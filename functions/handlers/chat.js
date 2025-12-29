// functions/handlers/chat.js
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { fetchClarifications } = require('../scraper/scrape');
const { getOpenAI, getOpenAIKey, withOpenAISecret } = require('../services/openai');
const { getAIConfig, getSofiaSystemPrompt } = require('../config/ai');
const { moderateText } = require('../services/moderation');
const axios = require('axios');
const cheerio = require('cheerio');
const { extractClarificationSections } = require('../scraper/parse');

try { admin.app(); } catch { admin.initializeApp(); }

function getBearerToken(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  return header.slice('Bearer '.length).trim() || null;
}

exports.chatWithGPT = onRequest(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB', ...withOpenAISecret },
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
      try {
        await admin.auth().verifyIdToken(idToken);
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
        if (mod.flagged) {
          return res.status(400).json({
            error: 'Your last message may violate content guidelines. Please rephrase.',
            categories: mod.categories,
          });
        }
      } catch (e) {
        console.warn('Moderation check failed:', e?.message || e);
        // soft-fail: continue
      }

      const openai = getOpenAI();
      const aiCfg = await getAIConfig();
      const sofiaModel = aiCfg.sofiaChat?.model || 'gpt-4o';
      const sofiaTemp =
        typeof aiCfg.sofiaChat?.temperature === 'number' ? aiCfg.sofiaChat.temperature : 0.6;

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

          const baseQ = messageText.slice(0, 300);
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

      // 2) Base system message for Sofia (centralized)
      const sofiaSystem = { role: 'system', content: getSofiaSystemPrompt() };

      // 3) Compose messages payload
      const messagesPayload = extraSystem
        ? [sofiaSystem, extraSystem, ...userMessages]
        : [sofiaSystem, ...userMessages];

      // 4) Chat completion
      const response = await openai.chat.completions.create({
        model: sofiaModel,
        messages: messagesPayload,
        max_tokens: 300,
        temperature: sofiaTemp,
      });

      res.json({ reply: response.choices[0].message.content });
    } catch (err) {
      console.error('OpenAI API error:', err);
      res.status(500).send('Error communicating with OpenAI');
    }
  }
);
