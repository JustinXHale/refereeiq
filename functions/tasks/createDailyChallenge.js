// Gen2 (v2) scheduler + HTTP "run now" with GPT generation (POC 5×5pts, hardened)

const { getAIConfig } = require('../config/ai');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onRequest }  = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

try { admin.app(); } catch { admin.initializeApp(); }
const db = admin.firestore();

// Default region for this module
setGlobalOptions({ region: 'us-central1' });

// --- Secrets ---
const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');

// --- Config ---
const TIME_ZONE = 'America/Chicago';

// -------- Helpers --------
function currentBlock(now = new Date()) {
  return now.getHours() < 12 ? 'am' : 'pm';
}
function todayId(now = new Date()) {
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}-${currentBlock(now)}`; // e.g., 2025-08-09-am
}
function idFor(dateStr, block) { // YYYY-MM-DD + am|pm
  const [y,m,d] = dateStr.split('-');
  return `${y}-${m}-${d}-${block}`;
}
function shuffle(a){ for (let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]];} return a; }
function sample(arr,n){ return shuffle([...arr]).slice(0, Math.min(n, arr.length)); }

// Normalize to our strict schema (5 pts, "standard")
function normalize(q) {
  const options = Array.isArray(q.options) ? q.options.map(String) : [];
  return {
    prompt: String(q.prompt ?? ''),
    options,
    correctIndex: Number.isInteger(q.correctIndex) ? q.correctIndex : 0,
    points: 5,
    difficulty: 'standard',
    lawReference: q.lawReference ? String(q.lawReference) : null,
    videoUrl: null,
    source: q.source || 'ai',
  };
}

// Basic local shape/consistency validation
function basicValidate(q) {
  if (!q || typeof q.prompt !== 'string' || !q.prompt.trim()) return 'bad prompt';
  if (!Array.isArray(q.options) || q.options.length !== 4) return 'need 4 options';
  const uniq = new Set(q.options.map(o => String(o).trim()));
  if (uniq.size !== 4) return 'options must be distinct';
  if (!Number.isInteger(q.correctIndex) || q.correctIndex < 0 || q.correctIndex > 3) return 'bad index';
  if (q.points !== 5) return 'points must be 5';
  if (q.difficulty !== 'standard') return 'difficulty must be "standard"';
  if (q.videoUrl !== null) return 'videoUrl must be null';
  return null;
}
function filterValid(questions) {
  return questions.filter(q => basicValidate(q) === null);
}

function extractJson(text) {
  try { return JSON.parse(text); } catch {}
  const m = text.match(/```json\s*([\s\S]*?)```/i);
  if (m) { try { return JSON.parse(m[1]); } catch {} }
  const m2 = text.match(/```\s*([\s\S]*?)```/);
  if (m2) { try { return JSON.parse(m2[1]); } catch {} }
  const start = text.indexOf('[');
  const end   = text.lastIndexOf(']');
  if (start >= 0 && end > start) {
    try { return JSON.parse(text.slice(start, end + 1)); } catch {}
  }
  throw new Error('Failed to parse JSON from model response');
}

// --- OpenAI call (uses native fetch, Node 20) ---
async function callOpenAIJSON(prompt, apiKey, { model, temperature }) {
  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      temperature,
      messages: [
        { role: 'system', content:
`You are Sofia, an expert Rugby Union assistant that writes fair, factual, law-accurate multiple-choice questions.

OUTPUT STRICTLY JSON. No commentary, no code fences unless asked.`
        },
        { role: 'user', content: prompt }
      ],
      response_format: { type: "text" }
    }),
  });

  if (!res.ok) {
    const t = await res.text();
    throw new Error(`OpenAI HTTP ${res.status}: ${t}`);
  }
  const json = await res.json();
  const content = json.choices?.[0]?.message?.content || '';
  return extractJson(content);
}

// Deterministic self-check to confirm correctIndex + law plausibility
async function verifyQuestionsWithModel(questions, apiKey, model) {
  const payload = {
    model,            // use the same model you generated with (or a stricter one if you prefer)
    temperature: 0.0, // deterministic verify
    messages: [{
      role: 'system',
      content:
`You verify Rugby Union MCQs. For each question:
- Choose the single correct option index (0..3).
- Briefly justify via World Rugby Law reference if relevant.
- Return STRICT JSON array of objects: { "agree": true|false, "correctIndex": number, "lawOk": true|false }.
No prose.`
    }, {
      role: 'user',
      content: JSON.stringify(questions.map(q => ({
        prompt: q.prompt,
        options: q.options,
        claimedCorrectIndex: q.correctIndex,
        lawReference: q.lawReference
      })))
    }]
  };

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });

  if (!res.ok) {
    const t = await res.text();
    throw new Error(`verify HTTP ${res.status}: ${t}`);
  }

  const data = await res.json();
  const content = data.choices?.[0]?.message?.content || '[]';

  let verdicts;
  try { verdicts = JSON.parse(content); } catch { verdicts = []; }

  const out = [];
  for (let i = 0; i < questions.length; i++) {
    const v = verdicts[i];
    const q = questions[i];
    if (!v || typeof v !== 'object') continue;

    const indexMatch = v.correctIndex === q.correctIndex;
    const lawOk = (v.lawOk === true) || q.lawReference === null;
    const agree = v.agree === true;

    if (agree && indexMatch && lawOk) out.push(q);
  }
  return out;
}

function buildPrompt({ usedPrompts }) {
  const avoid = Array.from(usedPrompts || []);
  const avoidBlock = avoid.length
    ? `Avoid reusing these prompt texts today:\n- ${avoid.join('\n- ')}`
    : `Do not reuse any prompt text used earlier today.`;

  return `
Create exactly 5 Rugby Union multiple-choice questions covering laws and match scenarios.
Scoring: every question is worth 5 points.

STRICT RULES:
- All answers MUST be based only on the official 2025 World Rugby Laws of the Game (Rugby Union), no outside interpretations.
- If unsure, omit the question rather than guess.
- Ensure the correct answer is the ONLY correct answer.
- Wording must match official law terminology exactly.
- Do not mix Rugby League or other sports content.

Each item MUST be an object with fields ONLY:
- prompt (string, <= 150 chars, unique today)
- options (array of 4 concise strings)
- correctIndex (0..3)
- points (always 5)
- difficulty ("standard")
- lawReference (string like "Law 18 - Mark", or null)
- videoUrl (null)

Constraints:
- Include a variety (set-piece, offside, tackle/ruck/maul, foul play, advantage, restarts).
- ${avoidBlock}

Return ONLY a JSON array (no prose, no code fences).
`;
}

// --- Fallback: use existing question_bank if AI fails ---
async function fallbackFromBank({ usedPrompts }) {
  const snap = await db.collection('question_bank').get();
  if (snap.empty) return null;

  const all = snap.docs
    .map(d => normalize({ ...d.data(), source: 'bank' }))
    .filter(q => q.prompt && q.options?.length === 4 && q.correctIndex < q.options.length)
    .filter(q => !usedPrompts.has(q.prompt));

  // just grab any 5 valid after normalization
  const picked = sample(all, 5);
  return filterValid(picked);
}

// Core generator used by both schedule + HTTP
async function generateFor({ dateId, apiKey }) {
  const outRef = db.collection('daily_challenges').doc(dateId);

  // Skip if already created
  if ((await outRef.get()).exists) {
    return { status: 'exists', id: dateId };
  }

  // Avoid duplicating prompts across blocks in the same day
  const [y,m,d,block] = dateId.split('-'); // ["2025","08","09","am"]
  const otherId = `${y}-${m}-${d}-${block === 'am' ? 'pm' : 'am'}`;
  const otherSnap = await db.collection('daily_challenges').doc(otherId).get();
  const usedPrompts = new Set(
    otherSnap.exists ? ((otherSnap.data().questions || []).map(q => String(q.prompt))) : []
  );

  // 1) Try to generate with OpenAI
  let questions = null;
  try {
    const prompt = buildPrompt({ usedPrompts });
    const aiCfg = await getAIConfig();              // ← read shared config
    const { model, temperature } = aiCfg.challenge; // e.g. gpt-4o @ 0.4
    const raw = await callOpenAIJSON(prompt, apiKey, { model, temperature });
    if (!Array.isArray(raw)) throw new Error('Model did not return an array');

    // normalize + local shape
    questions = filterValid(raw.map(normalize));

    // second-pass verify (deterministic)
    try {
      const verified = await verifyQuestionsWithModel(
        questions,
        OPENAI_API_KEY.value(),
        model // pass the same model you generated with (or a stricter one)
      );
      questions = verified;
    } catch (e) {
      console.warn('[daily] verify step failed:', e.message);
    }

    if (!questions || questions.length < 5) {
      throw new Error(`Too few verified questions: ${questions?.length || 0}`);
    }

    // exactly 5
    questions = questions.slice(0, 5);
  } catch (e) {
    console.warn('[daily] AI generation failed:', e.message);
  }

  // 2) Fallback to bank if AI failed
  if (!questions || questions.length < 5) {
    const bank = await fallbackFromBank({ usedPrompts });
    if (bank && bank.length === 5) {
      questions = bank;
    }
  }

  // 3) Last-resort placeholder
  if (!questions || questions.length === 0) {
    questions = [{
      prompt: 'Which law allows a quick throw-in?',
      options: ['Law 15','Law 16','Law 17','Law 18'],
      correctIndex: 3,
      points: 5,
      difficulty: 'standard',
      lawReference: 'Law 18',
      videoUrl: null,
      source: 'placeholder',
    }];
    await outRef.set({
      questions,
      block,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { status: 'placeholder', id: dateId, count: 1 };
  }

  await outRef.set({
    questions,
    block,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { status: 'created', id: dateId, count: questions.length };
}

// -------- Exports --------

// Scheduled (twice daily: 8:30am & 8:30pm CT)
exports.createDailyChallenge = onSchedule(
  { schedule: '30 8,20 * * *', timeZone: TIME_ZONE, secrets: [OPENAI_API_KEY] },
  async () => {
    const id = todayId(new Date());
    const result = await generateFor({ dateId: id, apiKey: OPENAI_API_KEY.value() });
    console.log(`[daily] ${result.status} for ${result.id}`);
  }
);

// HTTP "run now" for testing: ?date=YYYY-MM-DD&block=am|pm (both optional)
exports.createDailyChallengeNow = onRequest(
  { secrets: [OPENAI_API_KEY] },
  async (req, res) => {
    try {
      const date = (req.query.date || '').toString();                 // optional
      const block = (req.query.block || '').toString().toLowerCase(); // optional
      let id;

      if (date && (block === 'am' || 'pm' === block)) {
        id = idFor(date, block);
      } else if (date && !block) {
        const now = new Date();
        id = idFor(date, currentBlock(now));
      } else {
        id = todayId(new Date());
      }

      const result = await generateFor({ dateId: id, apiKey: OPENAI_API_KEY.value() });
      res.json(result);
    } catch (e) {
      console.error(e);
      res.status(500).json({ error: String(e) });
    }
  }
);
