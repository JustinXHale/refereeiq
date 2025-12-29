// functions/config/ai.js
const admin = require('firebase-admin');

// Safe init (in case this is imported before initializeApp runs)
try { admin.app(); } catch { admin.initializeApp(); }

/* ========= MODEL/TEMPERATURE DEFAULTS (edit here) ========= */
const DEFAULTS = {
  challenge:  { model: 'gpt-4o', temperature: 0.4 },
  sofiaChat:  { model: 'gpt-4o', temperature: 0.6 },
  moderation: { model: 'omni-moderation-latest', temperature: 0.0 },
};

/* ========= Live overrides from Firestore: app_config/ai ========= */
async function getAIConfig() {
  try {
    const snap = await admin.firestore().doc('app_config/ai').get();
    if (!snap.exists) return DEFAULTS;
    const data = snap.data() || {};
    return {
      challenge:  { ...DEFAULTS.challenge,  ...(data.challenge  || {}) },
      sofiaChat:  { ...DEFAULTS.sofiaChat,  ...(data.sofiaChat  || {}) },
      moderation: { ...DEFAULTS.moderation, ...(data.moderation || {}) },
    };
  } catch {
    return DEFAULTS;
  }
}

/* ========= Centralized prompts ========= */
const PROMPTS = {
  // Daily challenge generation (JSON-only MCQs)
  challenge: {
    system:
`You are Sofia, an expert Rugby Union assistant that writes fair, factual, law-accurate multiple-choice questions.

OUTPUT STRICTLY JSON. No commentary, no code fences unless asked.`,
    buildUser: ({ usedPrompts = [] }) => {
      const avoidBlock = usedPrompts.length
        ? `Avoid reusing these prompt texts today:\n- ${usedPrompts.join('\n- ')}`
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

Return ONLY a JSON array (no prose, no code fences).`;
    },
  },

  // Verification step for MCQs
  verify: {
    system:
`You verify Rugby Union MCQs. For each question:
- Choose the single correct option index (0..3).
- Briefly justify via World Rugby Law reference if relevant.
- Return STRICT JSON array of objects: { "agree": true|false, "correctIndex": number, "lawOk": true|false }.
No prose.`,
  },

  // Sofia chat assistant (in‑app Q&A)
  sofiaChat: {
    system:
`You are Sofia, an expert Rugby Union referee coach.
Be friendly and conversational—like a mentor texting their mentee.

ALWAYS follow this flow:
1. If the user's question is vague, scenario-based, or could depend on context:
   - First ask 1–2 short clarifying questions before giving any ruling.
   - Do not jump into an answer until the user replies with context.
2. If the question is concrete and factual (e.g., "How many points is a try?"), answer directly.

When answering:
- Give a clear, concise ruling in plain language and mention the relevant Law (e.g., "under Law 9.13").
- If teaching or judgment could vary, optionally add a small "Key considerations" list (max 3 bullets).
- Keep responses short, like a text conversation.

Never answer non-rugby questions.`,
  },
};

/* ========= Convenience getters ========= */
const getChallengeSystemPrompt = () => PROMPTS.challenge.system;
const buildChallengeUserPrompt = (args) => PROMPTS.challenge.buildUser(args);
const getVerifySystemPrompt = () => PROMPTS.verify.system;
const getSofiaSystemPrompt = () => PROMPTS.sofiaChat.system;

module.exports = {
  getAIConfig,
  PROMPTS,
  getChallengeSystemPrompt,
  buildChallengeUserPrompt,
  getVerifySystemPrompt,
  getSofiaSystemPrompt,
};
