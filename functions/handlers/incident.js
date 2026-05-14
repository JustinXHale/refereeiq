// functions/handlers/incident.js
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { getOpenAIKey, getLiteMaaSKey, withOpenAISecret } = require('../services/openai');
const { getAIProvider } = require('../services/aiProvider');
const crypto = require('crypto');
const { TAXONOMY_VERSION, INCIDENT_TAXONOMY } = require('../config/incident_taxonomy');

// json_schema for incidentAnalyze — clarifications always present (empty array when not needed)
const ANALYZE_SCHEMA = {
  type: 'object',
  properties: {
    message: { type: 'string' },
    needsClarification: { type: 'boolean' },
    clarifications: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id:            { type: 'string' },
          question:      { type: 'string' },
          options:       { type: 'array', items: { type: 'string' } },
          allowFreeText: { type: 'boolean' },
        },
        required: ['id', 'question', 'options', 'allowFreeText'],
        additionalProperties: false,
      },
    },
  },
  required: ['message', 'needsClarification', 'clarifications'],
  additionalProperties: false,
};

// json_schema for incidentRuling
const RULING_SCHEMA = {
  type: 'object',
  properties: {
    message: { type: 'string' },
    assessment: {
      type: 'object',
      properties: {
        decision:        { type: 'string' },
        law_refs:        { type: 'array', items: { type: 'string' } },
        explanation:     { type: 'string' },
        counterfactuals: { type: 'array', items: { type: 'string' } },
      },
      required: ['decision', 'law_refs', 'explanation', 'counterfactuals'],
      additionalProperties: false,
    },
  },
  required: ['message', 'assessment'],
  additionalProperties: false,
};

try { admin.app(); } catch { admin.initializeApp(); }

function getBearerToken(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  return header.slice('Bearer '.length).trim() || null;
}

function normalizeIncident(text) {
  return String(text || '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 2000);
}

function incidentHash(text) {
  return crypto.createHash('sha256').update(text).digest('hex');
}

function escapeRe(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function searchLawSnippets(query, version = '2025.0') {
  const q = String(query || '').trim();
  if (!q) return [];

  const snap = await admin.firestore().collection(`laws/${version}/chunks`).limit(500).get();
  if (snap.empty) return [];
  const items = snap.docs.map((d) => d.data());

  const terms = q.toLowerCase().split(/\s+/).filter(Boolean);
  const scored = items
    .map((it) => {
      const hay = (
        it.text + ' ' + it.sectionTitle + ' ' + it.lawRef + ' ' + (it.aliases || []).join(' ')
      ).toLowerCase();
      let score = 0;
      for (const t of terms) {
        const m = hay.match(new RegExp(`\\b${escapeRe(t)}\\b`, 'g'));
        score += m ? m.length : 0;
      }
      score += Math.max(0, 4 - Math.log10((it.tokens || 300) + 1));
      return { score, it };
    })
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 3)
    .map(({ it, score }) => ({
      score: Number(score.toFixed(2)),
      lawRef: it.lawRef,
      sectionTitle: it.sectionTitle,
      sourceUrl: it.sourceUrl,
      snippet: it.text.length > 300 ? it.text.slice(0, 300) + '…' : it.text,
    }));

  return scored;
}

function pickTaxonomyQuestions(incidentText) {
  const rules = INCIDENT_TAXONOMY;
  if (!rules.length) return [];

  const hay = normalizeIncident(incidentText);
  const answeredByText = new Set();
  const markIfMatch = (id, phrases) => {
    if (phrases.some((p) => hay.includes(p))) answeredByText.add(id);
  };
  markIfMatch('arrival_on_feet', [
    'off his feet',
    'off her feet',
    'off their feet',
    'went off feet',
    'going off feet',
    'on his feet',
    'on her feet',
    'on their feet',
    'stayed on feet',
    'stayed on their feet',
  ]);
  markIfMatch('supporting_body_weight', [
    'supporting their own body weight',
    'supporting his own body weight',
    'supporting her own body weight',
    'not supporting their body weight',
    'not supporting his body weight',
    'not supporting her body weight',
  ]);
  markIfMatch('ball_carrier_action', [
    'went to ground',
    'stayed on feet',
    'dove',
    'one knee',
  ]);
  const phaseKeywords = ['tackle', 'ruck', 'maul', 'scrum', 'lineout'];
  const phaseHits = phaseKeywords.filter((kw) => hay.includes(kw));
  const hasSinglePhase = phaseHits.length === 1;
  const escalationKeywords = [
    'dangerous',
    'foul play',
    'high tackle',
    'head',
    'neck',
    'shoulder',
    'punch',
    'strike',
    'stamp',
    'kick',
    'card',
    'repeated',
    'persistent',
    'yellow card',
    'red card',
    'sin bin',
    'sent off',
  ];
  const escalationHit = escalationKeywords.some((kw) => {
    if (kw.includes(' ')) return hay.includes(kw);
    return new RegExp(`\\b${escapeRe(kw)}\\b`).test(hay);
  });
  const hits = [];
  for (let i = 0; i < rules.length; i += 1) {
    const rule = rules[i];
    const keywords = Array.isArray(rule.keywords) ? rule.keywords : [];
    if (!keywords.length) continue;
    if (rule.id === 'phase_of_play' && hasSinglePhase) continue;
    if (rule.id === 'card_threshold' && !escalationHit) continue;
    if (answeredByText.has(rule.id)) continue;
    const matchedKeywords = keywords.filter((kw) =>
      hay.includes(String(kw).toLowerCase()),
    );
    if (!matchedKeywords.length) continue;
    hits.push({
      id: String(rule.id || ''),
      question: String(rule.question || ''),
      options: Array.isArray(rule.options) ? rule.options.map((o) => String(o)) : [],
      allowFreeText: rule.allowFreeText === true,
      matchedCount: matchedKeywords.length,
      order: i,
    });
  }
  hits.sort((a, b) => b.matchedCount - a.matchedCount || a.order - b.order);
  // Return 2–3 only; otherwise fallback to model.
  if (hits.length < 2) return [];
  return hits.slice(0, 3).map((hit) => ({
    id: hit.id,
    question: hit.question,
    options: hit.options,
    allowFreeText: hit.allowFreeText,
  }));
}


function shouldOrientIncident(incidentText) {
  const text = normalizeIncident(incidentText);
  if (!text) return false;
  if (text.includes('?')) return false;
  const questionWords = [
    'what',
    'why',
    'how',
    'should',
    'can',
    'is',
    'are',
    'does',
    'do',
    'did',
    'when',
    'where',
  ];
  if (questionWords.some((word) => new RegExp(`\\b${escapeRe(word)}\\b`).test(text))) {
    return false;
  }
  const wordCount = text.split(/\s+/).filter(Boolean).length;
  return wordCount <= 14;
}

exports.incidentAnalyze = onRequest(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB', ...withOpenAISecret },
  async (req, res) => {
    const incident = String(req.body?.incident || '').trim();
    if (!incident) {
      return res.status(400).json({ error: "Invalid request: 'incident' must be a non-empty string" });
    }

    try {
      const idToken = getBearerToken(req);
      if (!idToken) {
        return res.status(401).json({ error: 'Unauthorized: missing ID token' });
      }
      let uid;
      try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        uid = decodedToken.uid;
      } catch (e) {
        return res.status(401).json({ error: 'Unauthorized: invalid ID token' });
      }


      const provider = await getAIProvider({ OPENAI_API_KEY: getOpenAIKey(), LITEMAAS_API_KEY: getLiteMaaSKey() });

      const normalizedIncident = normalizeIncident(incident);
      const cacheKey = incidentHash(`${TAXONOMY_VERSION}::${normalizedIncident}`);
      const cacheRef = admin.firestore().collection('incident_cache').doc(cacheKey);

      if (shouldOrientIncident(incident)) {
        const responseBody = {
          message:
            'Could you clarify what you mean so I can walk through how refs think about this?',
          needsClarification: true,
          clarifications: [
            {
              id: 'focus_area',
              question:
                'What are you most unsure about in this situation?',
              options: [
                'Consequences of the action',
                'Attacking vs defending perspective',
                'Real-time decision making',
                'Something else',
              ],
              allowFreeText: true,
            },
          ],
        };
        try {
          await cacheRef.set({
            incident: normalizedIncident,
            response: responseBody,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (e) {
          console.warn('incidentAnalyze cache write failed:', e?.message || e);
        }

        // Log query history
        try {
          await admin.firestore().collection('query_history').add({
            uid,
            query: incident.slice(0, 2000),
            response: responseBody.message,
            query_type: 'incident_analyze',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
              incident_text: normalizedIncident.slice(0, 1000),
              had_clarifications: true,
            },
          });
        } catch (err) {
          console.error('Failed to log query history:', err);
        }

        return res.json(responseBody);
      }

      const taxonomyQuestions = pickTaxonomyQuestions(incident);

      if (taxonomyQuestions.length) {
        const responseBody = {
          message:
            'Could you clarify a couple details before we walk through how refs think about this?',
          needsClarification: true,
          clarifications: taxonomyQuestions,
        };
        try {
          await cacheRef.set({
            incident: normalizedIncident,
            response: responseBody,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (e) {
          console.warn('incidentAnalyze cache write failed:', e?.message || e);
        }

        // Log query history
        try {
          await admin.firestore().collection('query_history').add({
            uid,
            query: incident.slice(0, 2000),
            response: responseBody.message,
            query_type: 'incident_analyze',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
              incident_text: normalizedIncident.slice(0, 1000),
              had_clarifications: true,
            },
          });
        } catch (err) {
          console.error('Failed to log query history:', err);
        }

        return res.json(responseBody);
      }

      try {
        const cacheSnap = await cacheRef.get();
        if (cacheSnap.exists) {
          const cached = cacheSnap.data() || {};
          if (cached.response && typeof cached.response === 'object') {
            return res.json(cached.response);
          }
        }
      } catch (e) {
        console.warn('incidentAnalyze cache read failed:', e?.message || e);
      }

      const system = `
You help people understand rugby situations based on the laws of the game.

Your goal is NOT to make a ruling or give a definitive answer.
Your goal is to guide understanding of what matters in evaluating the situation.
Your tone is conversational and collaborative, not authoritative.

First, consider the user's intent:
- They may be asking a question
- They may be describing something they saw
- They may be unsure what details are important

Decide whether clarification is needed to think this through properly.

If clarification IS needed:
- Start with a brief, natural message acknowledging what they shared (1 sentence).
- Ask only the minimum number of questions (1–3) that would change how the situation is evaluated.
- Use clear, conversational language.
- Use stable snake_case ids.
- Use clear options when possible, but allow open-ended input when judgment or perspective matters.
- Avoid robotic phrases like "to better assist you".
- Prefer opening with "Could you clarify what you mean by ...".

If clarification is NOT needed:
- Provide a brief message explaining that you have enough context.

Return STRICT JSON only (no prose, no code fences).

Response schema:
{
  "message": string,
  "needsClarification": false
}
OR
{
  "message": string,
  "needsClarification": true,
  "clarifications": [
    {
      "id": string,
      "question": string,
      "options": string[],
      "allowFreeText": boolean
    }
  ]
}
`;

      const analyzeFormat = provider.supportsStructuredOutputs
        ? { type: 'json_schema', json_schema: { name: 'incident_analyze', strict: true, schema: ANALYZE_SCHEMA } }
        : { type: 'json_object' };

      const response = await provider.client.chat.completions.create({
        model: provider.models.chat,
        messages: [
          { role: 'system', content: system.trim() },
          { role: 'user', content: incident.slice(0, 2000) },
        ],
        temperature: 0.0,
        max_tokens: 300,
        response_format: analyzeFormat,
      });

      let data;
      try {
        data = JSON.parse(response.choices?.[0]?.message?.content || '');
      } catch {
        return res.status(500).json({ error: 'Invalid model response' });
      }
      if (!data || typeof data !== 'object') {
        return res.status(500).json({ error: 'Invalid model response' });
      }

      if (data.needsClarification === true) {
        const responseBody = {
          message: String(data.message || "I need a bit more context:"),
          needsClarification: true,
          clarifications: Array.isArray(data.clarifications) ? data.clarifications : [],
        };
        try {
          await cacheRef.set({
            incident: normalizedIncident,
            response: responseBody,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (e) {
          console.warn('incidentAnalyze cache write failed:', e?.message || e);
        }

        // Log query history
        try {
          await admin.firestore().collection('query_history').add({
            uid,
            query: incident.slice(0, 2000),
            response: responseBody.message,
            query_type: 'incident_analyze',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
              incident_text: normalizedIncident.slice(0, 1000),
              had_clarifications: true,
            },
          });
        } catch (err) {
          console.error('Failed to log query history:', err);
        }

        return res.json(responseBody);
      }

      const responseBody = {
        message: String(data.message || "I have enough context to work with this."),
        needsClarification: false
      };
      try {
        await cacheRef.set({
          incident: normalizedIncident,
          response: responseBody,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (e) {
        console.warn('incidentAnalyze cache write failed:', e?.message || e);
      }

      // Log query history
      try {
        await admin.firestore().collection('query_history').add({
          uid,
          query: incident.slice(0, 2000),
          response: responseBody.message,
          query_type: 'incident_analyze',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            incident_text: normalizedIncident.slice(0, 1000),
            had_clarifications: false,
          },
        });
      } catch (err) {
        console.error('Failed to log query history:', err);
      }

      return res.json(responseBody);
    } catch (err) {
      console.error('incidentAnalyze error:', err);
      return res.status(500).json({ error: 'Error analyzing incident' });
    }
  }
);

exports.incidentRuling = onRequest(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB', ...withOpenAISecret },
  async (req, res) => {
    const incident = String(req.body?.incident || '').trim();
    const answers = req.body?.answers;
    const followUp = String(req.body?.followUp || '').trim();
    const context = Array.isArray(req.body?.context) ? req.body.context : [];
    if (!incident) {
      return res.status(400).json({ error: "Invalid request: 'incident' must be a non-empty string" });
    }
    if (!answers || typeof answers !== 'object') {
      return res.status(400).json({ error: "Invalid request: 'answers' must be an object" });
    }

    try {
      const idToken = getBearerToken(req);
      if (!idToken) {
        return res.status(401).json({ error: 'Unauthorized: missing ID token' });
      }
      let uid;
      try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        uid = decodedToken.uid;
      } catch (e) {
        return res.status(401).json({ error: 'Unauthorized: invalid ID token' });
      }

      const provider = await getAIProvider({ OPENAI_API_KEY: getOpenAIKey(), LITEMAAS_API_KEY: getLiteMaaSKey() });

      const formattedAnswers = Object.entries(answers)
        .map(([k, v]) => `- ${k}: ${String(v)}`)
        .join('\n');

      const lawQuery = `${incident}\n${formattedAnswers}`;
      let lawResults = [];
      try {
        lawResults = await searchLawSnippets(lawQuery);
      } catch (e) {
        console.warn('incidentRuling law search failed:', e?.message || e);
      }
      const referencesText = lawResults.length
        ? lawResults
            .map(
              (r, i) =>
                `[${i + 1}] ${r.lawRef || 'Law'} — ${r.sectionTitle || 'Untitled'}\n${r.snippet}`,
            )
            .join('\n\n')
        : 'None';

      const contextText = context
        .map((entry) => {
          const role = String(entry?.role || entry?.sender || '').trim();
          const content = String(entry?.content || entry?.text || '').trim();
          if (!content) return null;
          return `${role || 'context'}: ${content}`;
        })
        .filter(Boolean)
        .slice(-8)
        .join('\n')
        .slice(0, 1500);

      const system = `
You help people understand rugby situations based on the laws of the game.

Your role is NOT to issue a ruling, but to explain how the situation is typically evaluated.
Your tone is conversational and collaborative, not authoritative.

Guidelines:
- "decision" should describe what the laws indicate about this situation (not a verdict).
- "explanation" should teach: what details matter, why they matter, what the laws say.
- Provide 1–2 counterfactuals showing how small changes would shift the evaluation.
- Reference relevant laws when helpful (include law_refs array).
- Use conditional language when details are uncertain ("If X, then..." or "Based on what you described...").
- Treat user clarifications and follow-ups as more reliable than the original incident text.
- Include a brief conversational response in "message" before the assessment.

Return STRICT JSON only (no prose, no code fences).

Response schema:
{
  "message": string,
  "assessment": { "decision": string, "law_refs": string[], "explanation": string, "counterfactuals": string[] }
}
`;

      const rulingFormat = provider.supportsStructuredOutputs
        ? { type: 'json_schema', json_schema: { name: 'incident_ruling', strict: true, schema: RULING_SCHEMA } }
        : { type: 'json_object' };

      const response = await provider.client.chat.completions.create({
        model: provider.models.chat,
        messages: [
          { role: 'system', content: system.trim() },
          {
            role: 'user',
            content: `Conversation context:\n${contextText || 'None'}\n\nIncident:\n${incident.slice(0, 2000)}\n\nClarifications:\n${formattedAnswers || 'None'}\n\nFollow-up:\n${followUp || 'None'}\n\nReferences:\n${referencesText}`,
          },
        ],
        temperature: 0.2,
        max_tokens: 500,
        response_format: rulingFormat,
      });

      let data;
      try {
        data = JSON.parse(response.choices?.[0]?.message?.content || '');
      } catch {
        return res.status(500).json({ error: 'Invalid model response' });
      }
      if (!data || typeof data !== 'object' || !data.assessment) {
        return res.status(500).json({ error: 'Invalid model response' });
      }

      const result = data.assessment;
      const assessment = {
        decision: String(result.decision || result.ruling || ''),
        law_refs: Array.isArray(result.law_refs)
          ? result.law_refs.map((r) => String(r))
          : [],
        explanation: String(result.explanation || ''),
        counterfactuals: Array.isArray(result.counterfactuals)
          ? result.counterfactuals.map((c) => String(c))
          : [],
      };

      // Log query history
      const normalizedIncident = normalizeIncident(incident);
      try {
        await admin.firestore().collection('query_history').add({
          uid,
          query: incident.slice(0, 2000),
          response: JSON.stringify(assessment),
          query_type: 'incident_ruling',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            incident_text: normalizedIncident.slice(0, 1000),
            had_clarifications: Object.keys(answers || {}).length > 0,
            law_refs: assessment.law_refs,
          },
        });
      } catch (err) {
        console.error('Failed to log query history:', err);
      }

      return res.json({
        message: String(data.message || ''),
        assessment,
      });
    } catch (err) {
      console.error('incidentRuling error:', err);
      return res.status(500).json({ error: 'Error generating assessment' });
    }
  }
);
