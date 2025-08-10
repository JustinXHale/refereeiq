// Gen2 (v2) scheduler + HTTP "run now" with GPT generation

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
const TARGET = { easy: 2, medium: 2, hard: 1 }; // 2×3pt, 2×5pt, 1×7pt
const MODEL  = 'gpt-4o-mini';                   // fast+cheap; change if you want

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

function normalize(q) {
  const options = Array.isArray(q.options) ? q.options.map(String) : [];
  const points = Number.isInteger(q.points) ? q.points : 1;
  const difficulty = (q.difficulty || '').toString().toLowerCase();
  const tag = ['easy','medium','hard'].includes(difficulty)
    ? difficulty
    : points === 3 ? 'easy'
    : points === 5 ? 'medium'
    : points === 7 ? 'hard'
    : 'medium';

  return {
    prompt: String(q.prompt ?? ''),
    options,
    correctIndex: Number.isInteger(q.correctIndex) ? q.correctIndex : 0,
    points,
    difficulty: tag,
    lawReference: q.lawReference ? String(q.lawReference) : null,
    videoUrl: q.videoUrl ? String(q.videoUrl) : null,
    source: 'ai',
  };
}

function extractJson(text) {
  // try raw
  try { return JSON.parse(text); } catch {}
  // try ```json ... ```
  const m = text.match(/```json\s*([\s\S]*?)```/i);
  if (m) { try { return JSON.parse(m[1]); } catch {} }
  // try any fenced ```
  const m2 = text.match(/```\s*([\s\S]*?)```/);
  if (m2) { try { return JSON.parse(m2[1]); } catch {} }
  // last resort: strip leading/trailing junk
  const start = text.indexOf('[');
  const end   = text.lastIndexOf(']');
  if (start >= 0 && end > start) {
    try { return JSON.parse(text.slice(start, end + 1)); } catch {}
  }
  throw new Error('Failed to parse JSON from model response');
}

// --- OpenAI call (uses native fetch, Node 20) ---
async function callOpenAIJSON(prompt, apiKey) {
  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: MODEL,
      temperature: 0.4,
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

function buildPrompt({ usedPrompts }) {
  // Make sure we avoid prompts already used earlier today
  const avoid = Array.from(usedPrompts || []);
  const avoidBlock = avoid.length
    ? `Avoid reusing these prompt texts today:\n- ${avoid.join('\n- ')}`
    : `Do not reuse any prompt text used earlier today.`;

  // Exactly 5 questions with the desired mix
  return `
Create exactly 5 Rugby Union multiple-choice questions covering laws and match scenarios.
Mix and scoring MUST be:
- 2 EASY worth 3 points
- 2 MEDIUM worth 5 points
- 1 HARD worth 7 points

Each item MUST be an object with fields:
- prompt (string, <= 150 chars, unique today)
- options (array of 4 concise strings)
- correctIndex (0..3)
- points (3|5|7)
- difficulty ("easy"|"medium"|"hard")
- lawReference (string like "Law 18 - Mark", or null)
- videoUrl (null)

Constraints:
- Stay within World Rugby Laws (Rugby Union).
- Keep answers unambiguous & factually correct for current law interpretations.
- Include a variety (set-piece, offside, tackle/ruck/maul, foul play, advantage, restarts).
- ${avoidBlock}

Return ONLY a JSON array (no prose).`;
}

// --- Fallback: use existing question_bank if AI fails ---
async function fallbackFromBank({ usedPrompts }) {
  const snap = await db.collection('question_bank').get();
  if (snap.empty) return null;

  const all = snap.docs
    .map(d => normalize({ ...d.data(), source: 'bank' }))
    .filter(q => q.prompt && q.options?.length >= 2 && q.correctIndex < q.options.length)
    .filter(q => !usedPrompts.has(q.prompt));

  const easy   = all.filter(q => q.difficulty === 'easy'   || q.points === 3);
  const medium = all.filter(q => q.difficulty === 'medium' || q.points === 5);
  const hard   = all.filter(q => q.difficulty === 'hard'   || q.points === 7);

  let picked = [];
  picked.push(...sample(easy,   TARGET.easy));
  picked.push(...sample(medium, TARGET.medium));
  picked.push(...sample(hard,   TARGET.hard));

  const need = 5 - picked.length;
  if (need > 0) {
    const chosen = new Set(picked.map(q => q.prompt));
    const remaining = shuffle(all).filter(q => !chosen.has(q.prompt));
    picked.push(...remaining.slice(0, need));
  }
  return picked.slice(0, 5);
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
    const raw = await callOpenAIJSON(prompt, apiKey);
    if (!Array.isArray(raw)) throw new Error('Model did not return an array');
    questions = raw.map(normalize);

    // enforce counts & shape
    const okLen = questions.length >= 5;
    const counts = {
      easy:   questions.filter(q => q.points === 3 || q.difficulty === 'easy').length,
      medium: questions.filter(q => q.points === 5 || q.difficulty === 'medium').length,
      hard:   questions.filter(q => q.points === 7 || q.difficulty === 'hard').length,
    };
    if (!okLen || counts.easy < 2 || counts.medium < 2 || counts.hard < 1) {
      throw new Error(`Mix invalid from AI: ${JSON.stringify(counts)}`);
    }

    // trim to exactly the mix (2/2/1)
    const easyQs   = questions.filter(q => q.points === 3 || q.difficulty === 'easy').slice(0, 2);
    const mediumQs = questions.filter(q => q.points === 5 || q.difficulty === 'medium').slice(0, 2);
    const hardQs   = questions.filter(q => q.points === 7 || q.difficulty === 'hard').slice(0, 1);
    questions = [...easyQs, ...mediumQs, ...hardQs];
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
      points: 3,
      difficulty: 'easy',
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

// Scheduled (twice daily: 6:05am & 6:05pm, America/Chicago)
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
      const date = (req.query.date || '').toString();           // optional
      const block = (req.query.block || '').toString().toLowerCase(); // optional
      let id;

      if (date && (block === 'am' || block === 'pm')) {
        id = idFor(date, block);
      } else if (date && !block) {
        // if only date is given, default to current block for that date
        const now = new Date();
        id = idFor(date, currentBlock(now));
      } else {
        // default: today + current block
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
