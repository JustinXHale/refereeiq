// functions/handlers/chat.js
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { fetchClarifications } = require('../scraper/scrape');
const { getOpenAIKey, getLiteMaaSKey, withOpenAISecret } = require('../services/openai');
const { getAIProvider } = require('../services/aiProvider');
const { getPrompts } = require('../config/ai');
const { moderateText } = require('../services/moderation');
const axios = require('axios');
const cheerio = require('cheerio');
const { extractClarificationSections } = require('../scraper/parse');
const crypto = require('crypto');

try { admin.app(); } catch { admin.initializeApp(); }

function normalizeSofiaQuery(text) {
  return String(text || '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 2000);
}

/** Sofia chat: cheap tier only when single-turn, short, no law/clarification augmentation. */
function classifySofiaChatTier(userMessages, extraSystem, messageText) {
  if (extraSystem) return 'full';
  const userMsgs = userMessages.filter((m) => m?.role === 'user');
  if (userMsgs.length > 1) return 'full';
  if (String(messageText || '').length > 500) return 'full';
  if (userMessages.length > 3) return 'full';
  return 'simple';
}

function extractLawRefsFromReply(text) {
  const lawRefs = [];
  const lawRefPattern = /Law\s+(\d{1,2}(?:\.\d{1,2})?)/gi;
  let match;
  while ((match = lawRefPattern.exec(text)) !== null) {
    if (!lawRefs.includes(match[1])) lawRefs.push(match[1]);
  }
  return lawRefs;
}

/** OpenAI-compatible APIs may return string, null, or content-part arrays. */
function extractAssistantText(message) {
  if (!message) return '';
  const c = message.content;
  if (typeof c === 'string') return c;
  if (c == null) return '';
  if (Array.isArray(c)) {
    return c
      .map((part) => {
        if (typeof part === 'string') return part;
        if (part && typeof part === 'object') {
          if (part.type === 'text' && typeof part.text === 'string') return part.text;
          if (part.type === 'output_text') {
            if (typeof part.text === 'string') return part.text;
            if (typeof part.output_text === 'string') return part.output_text;
          }
          if (typeof part.content === 'string') return part.content;
        }
        return '';
      })
      .join('');
  }
  if (typeof c === 'object' && c !== null) {
    if (typeof c.text === 'string') return c.text;
    if (typeof c.value === 'string') return c.value;
  }
  return '';
}

/** Some gateways use choice.text; reasoning models may fill reasoning_* when content is empty. */
function extractAssistantTextFromChoice(choice) {
  if (!choice) return '';
  if (typeof choice.text === 'string' && choice.text.trim()) {
    return choice.text.trim();
  }
  const msg = choice.message;
  const fromContent = extractAssistantText(msg).trim();
  if (fromContent) return fromContent;
  if (!msg || typeof msg !== 'object') return '';
  const rc = msg.reasoning_content ?? msg.reasoning;
  if (typeof rc === 'string' && rc.trim()) {
    const t = rc.trim();
    return t.length > 8000 ? `${t.slice(0, 8000)}\n\n…` : t;
  }
  return '';
}

function getBearerToken(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  return header.slice('Bearer '.length).trim() || null;
}

exports.chatWithGPT = onRequest(
  { region: 'us-central1', timeoutSeconds: 120, memory: '256MiB', ...withOpenAISecret },
  async (req, res) => {
    const userMessages = req.body?.messages;
    if (!Array.isArray(userMessages) || userMessages.length === 0) {
      return res.status(400).json({ error: "Invalid request: 'messages' must be a non-empty array" });
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

      // 1) Moderation (aggregate recent user text)
      const combinedUserText = (userMessages || [])
        .filter((m) => m?.role === 'user')
        .map((m) => String(m?.content || ''))
        .join('\n')
        .slice(0, 4000);

      try {
        const mod = await moderateText(combinedUserText, getOpenAIKey());
        const categories = mod.categories || {};
        const hasOnlySportsViolence =
          categories.violence === true &&
          categories['violence/graphic'] !== true &&
          !categories.hate &&
          !categories['hate/threatening'] &&
          !categories.harassment &&
          !categories['harassment/threatening'] &&
          !categories.sexual &&
          !categories['sexual/minors'] &&
          !categories.self_harm &&
          !categories['self-harm'] &&
          !categories['self-harm/intent'] &&
          !categories['self-harm/instructions'] &&
          !categories.illicit &&
          !categories['illicit/violent'];
        const looksLikeRugby =
          /\b(rugby|tackle|ruck|maul|scrum|lineout|kick|kicker|in-goal|offside|breakdown|yellow card|red card|sin bin)\b/i
            .test(combinedUserText);

        if (mod.flagged && !(hasOnlySportsViolence && looksLikeRugby)) {
          return res.status(400).json({
            error: 'Your last message may violate content guidelines. Please rephrase.',
            categories: mod.categories,
          });
        }
      } catch (e) {
        console.warn('Moderation check failed:', e?.message || e);
        // soft-fail: continue
      }

      // ---- Clarifications-aware augmentation for Sofia Chat ----
      const lastUserText =
        [...userMessages].reverse().find((m) => m?.role === 'user')?.content ?? '';
      const messageText = String(lastUserText || '');

      const numberYearRe = /(?:(?:clarif(?:ication)?\s*)?)(\d{1,2})\s*[-\/]\s*((?:19|20)\d{2})/i;
      const wantsSummary = /\b(summarize|summary|excerpt|quote|tl;dr|tldr)\b/i.test(messageText);
      const latestAsk = /latest|newest|most\s+recent/i.test(messageText);
      const mentionsClarifWord = /\bclarif(?:ication|ications)?\b/i.test(messageText);
      const specific = numberYearRe.exec(messageText);
      const urlMatch = /(https:\/\/passport\.world\.rugby\/[\w\-\/]+)/i.exec(messageText);

      let extraSystem = null;

      if (mentionsClarifWord || latestAsk || wantsSummary || specific || urlMatch) {
        try {
          const data = await fetchClarifications();

          async function pullSections(url) {
            const { data: html } = await axios.get(url, {
              headers: {
                'User-Agent': 'RefereeIQ Bot (axios)',
                'Accept-Language': 'en-US,en;q=0.9',
              },
              timeout: 20000,
            });
            const $ = cheerio.load(html);
            const { sections } = extractClarificationSections($);
            const block = sections.map((s) => `# ${s.heading}\n${s.text}`).join('\n\n').slice(0, 1500);
            return block;
          }

          let ctx = '';

          if (urlMatch) {
            const url = urlMatch[1];
            ctx = `Direct clarification link detected: ${url}`;
            if (wantsSummary) {
              try { ctx += `\n\nSource excerpt:\n${await pullSections(url)}`; } catch {}
            }
          } else if (specific) {
            const num = String(Number(specific[1]));
            const yr = specific[2];
            const list = data.clarifications?.[yr] || [];
            const item = list.find((it) => String(it.number) === num);
            if (item) {
              ctx = `Specific clarification requested: ${item.title} (${yr}). URL: ${item.url}`;
              if (wantsSummary) {
                try { ctx += `\n\nSource excerpt:\n${await pullSections(item.url)}`; } catch {}
              }
            } else {
              ctx = `No exact match for Clarification ${num}-${yr}. Available for ${yr}: ${list.map((it) => it.title).join(', ')}`;
            }
          } else if (latestAsk) {
            const y = data.years?.[0];
            const latest = y ? data.clarifications?.[y]?.slice(-1)[0] : null;
            if (latest) {
              ctx = `Latest clarification: ${latest.title} (${y}). URL: ${latest.url}`;
              if (wantsSummary) {
                try { ctx += `\n\nSource excerpt:\n${await pullSections(latest.url)}`; } catch {}
              }
            }
          } else {
            const yearOnly = /(?:^|\D)((?:19|20)\d{2})(?:\D|$)/i.exec(messageText);
            if (yearOnly) {
              const y = yearOnly[1];
              const list = data.clarifications?.[y] || [];
              ctx = list.length
                ? `Clarifications for ${y}: ${list.map((it) => `${it.title} → ${it.url}`).join(' | ')}`
                : `No clarifications found for ${y}.`;
            } else {
              const y = data.years?.[0];
              const list = data.clarifications?.[y] || [];
              ctx = list.length
                ? `Most recent year ${y}. Clarifications: ${list.map((it) => `${it.title} → ${it.url}`).join(' | ')}`
                : '';
            }
          }

          if (ctx) {
            extraSystem = {
              role: 'system',
              content: [
                'Use the following authoritative data when answering about law clarifications.',
                'When you include a clarification link, ALWAYS format it as Markdown with the label VIEW, exactly like:',
                '1. Clarification 3-2025: [VIEW](https://passport.world.rugby/laws-of-the-game/law-clarifications/2025/clarification-3-2025/)',
                'If you list multiple clarifications, use a numbered list in that exact format.',
                'If you summarize a single clarification, put the VIEW link on its own final line.',
                'Never insert spaces or line breaks inside URLs; keep each URL as one continuous string.',
                '',
                ctx,
              ].join('\n'),
            };
          }
        } catch (e) {
          console.warn('Clarifications augmentation failed', e?.message || e);
        }
      }

      // ---- Law-search augmentation (lightweight RAG) ----
      try {
        const maybeLawQuery = /\b(law|quick throw|lineout|scrum|tackle|ruck|maul|offside|restart|mark|penalty|free[-\s]?kick|in-?goal|drop[-\s]?out|goal[-\s]?line)\b/i
          .test(messageText);

        if (maybeLawQuery) {
          const lawsSearchUrl =
            process.env.LAWS_SEARCH_URL || 'https://lawssearch-s6ub2qfhfq-uc.a.run.app';

          // Expanded query heuristic: if user describes “attack kicks into in-goal, defence grounds”
          const isGLDOPattern = /(attack|attacking|offen[cs]e|kicker).*(kick|kicks|kicked).*(in[\s-]?goal|ing[o|-]al).*(defen[cs]e|defender).*(ground|make[s]? (it )?dead|touch(es)? down)/i
            .test(messageText);

          const baseQ = messageText.slice(0, 180);
          const expandedQ = isGLDOPattern
            ? 'goal line drop out GLDO 12.12 in-goal grounded by defence'
            : '';

          const queries = [baseQ].concat(expandedQ ? [expandedQ] : []);

          // Run searches and merge results
          const resultsArrays = await Promise.all(
            queries.map(async (q) => {
              const r = await axios.get(lawsSearchUrl, {
                params: { q, version: '2025.0' },
                timeout: 8000,
                validateStatus: () => true,
              });
              if (r.status === 200 && Array.isArray(r.data?.results)) return r.data.results;
              console.warn('lawsSearch non-200 or bad response:', r.status, r.data);
              return [];
            })
          );

          // Dedupe by URL + section
          const seen = new Set();
          const merged = [];
          for (const arr of resultsArrays) {
            for (const it of arr) {
              const key = `${it.sourceUrl}::${it.sectionTitle}`;
              if (seen.has(key)) continue;
              seen.add(key);
              merged.push(it);
            }
          }

          // Prefer GLDO/guideline hits to float them up
          merged.sort((a, b) => {
            const aBoost = /gldo|goal[-\s]?line drop-?out/i.test(`${a.lawRef} ${a.sectionTitle} ${a.snippet}`) ? 1 : 0;
            const bBoost = /gldo|goal[-\s]?line drop-?out/i.test(`${b.lawRef} ${b.sectionTitle} ${b.snippet}`) ? 1 : 0;
            if (aBoost !== bBoost) return bBoost - aBoost;
            return (b.score || 0) - (a.score || 0);
          });

          const top = merged.slice(0, 3);
          if (top.length) {
            const lawCtx = top
              .map((r, i) =>
                `${i + 1}. ${r.lawRef} — ${r.sectionTitle}\n${r.snippet}\nVIEW: [VIEW](${r.sourceUrl})`
              )
              .join('\n\n');

            if (!extraSystem) extraSystem = { role: 'system', content: '' };
            extraSystem.content += `\n\nUse these law snippets as ground truth when relevant. Cite them and avoid inventing law numbers:\n${lawCtx}\n\nNote: If attackers kick into opponents’ in-goal and defenders ground it, that is a GLDO (Law 12.12).`;
          }
        }
      } catch (e) {
        console.warn('lawsSearch augmentation failed:', e?.message || e);
      }

      const chatTier = classifySofiaChatTier(userMessages, extraSystem, messageText);
      const provider = await getAIProvider(
        { OPENAI_API_KEY: getOpenAIKey(), LITEMAAS_API_KEY: getLiteMaaSKey() },
        { chatTier },
      );
      const { client: openai, models, temperature: temps } = provider;
      const sofiaModel = models.chat;
      const sofiaTemp = temps.chat;

      const cacheEligible =
        chatTier === 'simple' &&
        userMessages.filter((m) => m?.role === 'user').length === 1;

      let cacheRef = null;
      if (cacheEligible) {
        const normalized = normalizeSofiaQuery(messageText);
        const qHash = crypto.createHash('sha256').update(`sofia_v1::${normalized}`).digest('hex');
        cacheRef = admin.firestore().collection('sofia_chat_cache').doc(`${uid}_${qHash}`);
        try {
          const cacheSnap = await cacheRef.get();
          if (cacheSnap.exists) {
            const cached = cacheSnap.data() || {};
            if (typeof cached.response === 'string' && cached.response.length > 0) {
              const assistantReply = cached.response;
              const lawRefs = extractLawRefsFromReply(assistantReply);
              const lastUserMessage = [...userMessages].reverse().find((m) => m?.role === 'user');
              const userQuery = lastUserMessage?.content || '';
              try {
                await admin.firestore().collection('query_history').add({
                  uid,
                  query: userQuery.slice(0, 2000),
                  response: assistantReply.slice(0, 5000),
                  query_type: 'chat',
                  timestamp: admin.firestore.FieldValue.serverTimestamp(),
                  metadata: {
                    message_count: userMessages.length,
                    law_refs: lawRefs,
                    cache_hit: true,
                    chat_tier: chatTier,
                  },
                });
              } catch (err) {
                console.error('Failed to log query history:', err);
              }
              return res.json({ reply: assistantReply });
            }
          }
        } catch (e) {
          console.warn('sofia_chat_cache read failed:', e?.message || e);
        }
      }

      // 2) Base system message for Sofia (Firestore-controlled, falls back to hardcoded)
      const prompts = await getPrompts();
      const sofiaSystem = { role: 'system', content: prompts.sofiaChat.system };

      // 3) Compose messages payload
      const messagesPayload = extraSystem
        ? [sofiaSystem, extraSystem, ...userMessages]
        : [sofiaSystem, ...userMessages];

      // 4) Chat completion
      // Generous cap: reasoning/thinking models can consume hundreds of "hidden" tokens
      // before emitting visible content; a low max_tokens often yields empty message.content.
      const response = await openai.chat.completions.create({
        model: sofiaModel,
        messages: messagesPayload,
        max_tokens: 2048,
        temperature: sofiaTemp,
      });

      const choice0 = response.choices?.[0];
      const assistantReply = extractAssistantTextFromChoice(choice0);

      if (!assistantReply) {
        const finish = choice0?.finish_reason ?? 'unknown';
        let messageDebug = '';
        try {
          messageDebug = JSON.stringify(choice0?.message ?? null).slice(0, 1800);
        } catch (_) {
          messageDebug = 'unserializable';
        }
        console.warn('chatWithGPT empty assistant content', {
          finish,
          model: response.model,
          choiceCount: response.choices?.length ?? 0,
          messageKeys: choice0?.message && typeof choice0.message === 'object'
            ? Object.keys(choice0.message)
            : [],
          messageDebug,
        });
        return res.status(502).json({
          error:
            'The AI returned an empty response. Try again, shorten your message, or check the model configuration.',
        });
      }

      // Log query/response pair to Firestore
      const lawRefs = extractLawRefsFromReply(assistantReply);

      if (cacheRef && cacheEligible) {
        try {
          await cacheRef.set({
            uid,
            response: assistantReply,
            chatTier,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (e) {
          console.warn('sofia_chat_cache write failed:', e?.message || e);
        }
      }

      // Extract user's last query
      const lastUserMessage = [...userMessages].reverse().find((m) => m?.role === 'user');
      const userQuery = lastUserMessage?.content || '';

      try {
        await admin.firestore().collection('query_history').add({
          uid,
          query: userQuery.slice(0, 2000),
          response: assistantReply.slice(0, 5000),
          query_type: 'chat',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            message_count: userMessages.length,
            law_refs: lawRefs,
            cache_hit: false,
            chat_tier: chatTier,
          },
        });
      } catch (err) {
        console.error('Failed to log query history:', err);
      }

      res.json({ reply: assistantReply });
    } catch (err) {
      console.error('chatWithGPT error:', err);
      const message = err?.message || String(err);
      if (message.startsWith('AI_CONFIG:')) {
        return res.status(400).json({
          error: message.replace(/^AI_CONFIG:\s*/, ''),
        });
      }
      res.status(500).json({ error: 'AI provider request failed.' });
    }
  }
);
