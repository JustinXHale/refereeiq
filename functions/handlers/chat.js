const { onRequest } = require('firebase-functions/v2/https');
const { fetchClarifications } = require('../scraper/scrape');
const { getOpenAI, withOpenAISecret } = require('../services/openai');
const axios = require('axios');
const cheerio = require('cheerio');
const { extractClarificationSections } = require('../scraper/parse');

exports.chatWithGPT = onRequest(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB', ...withOpenAISecret },
  async (req, res) => {
    const userMessages = req.body?.messages;
    if (!Array.isArray(userMessages) || userMessages.length === 0) {
      return res
        .status(400)
        .json({ error: "Invalid request: 'messages' must be a non-empty array" });
    }

    try {
      const openai = getOpenAI();

      // ---- Clarifications-aware augmentation for Sofia Chat ----
      const lastUserText =
        [...userMessages].reverse().find((m) => m?.role === 'user')?.content ?? '';

      const messageText = String(lastUserText || '');

      // Broaden the trigger: kick in if they mention clarifications, ask for latest,
      // include a number-year like "2-2025", or ask to summarize/excerpt.
      const numberYearRe = /(?:(?:clarif(?:ication)?\s*)?)(\d{1,2})\s*[-\/]\s*((?:19|20)\d{2})/i;
      const wantsSummary = /\b(summarize|summary|excerpt|quote|tl;dr|tldr)\b/i.test(messageText);
      const latestAsk = /latest|newest|most\s+recent/i.test(messageText);
      const mentionsClarifWord = /\bclarif(?:ication|ications)?\b/i.test(messageText);
      const specific = numberYearRe.exec(messageText); // works with or without the word "clarification"
      const urlMatch = /(https:\/\/passport\.world\.rugby\/[\w\-\/]+)/i.exec(messageText);

      let extraSystem = null;

      if (mentionsClarifWord || latestAsk || wantsSummary || specific || urlMatch) {
        try {
          const data = await fetchClarifications();

          // helper to fetch & parse sections
          async function pullSections(url) {
            const { data: html } = await axios.get(url, {
              headers: {
                'User-Agent': 'RefereeIQ Bot (testing) - axios',
                'Accept-Language': 'en-US,en;q=0.9',
              },
              timeout: 20000,
            });
            const $ = cheerio.load(html);
            const { sections } = extractClarificationSections($);
            const block = sections
              .map((s) => `# ${s.heading}\n${s.text}`)
              .join('\n\n')
              .slice(0, 1500); // cap length for prompt
            return block;
          }

          let ctx = '';

          // Case A: user pasted a URL directly
          if (urlMatch) {
            const url = urlMatch[1];
            ctx = `Direct clarification link detected: ${url}`;
            if (wantsSummary) {
              try {
                const block = await pullSections(url);
                ctx += `\n\nSource excerpt:\n${block}`;
              } catch (e) {
                console.warn('section fetch (by URL) failed', e?.message || e);
              }
            }
          }
          // Case B: specific number-year like "2-2025"
          else if (specific) {
            const num = String(Number(specific[1]));
            const yr = specific[2];
            const list = data.clarifications?.[yr] || [];
            const item = list.find((it) => String(it.number) === num);
            if (item) {
              ctx = `Specific clarification requested: ${item.title} (${yr}). URL: ${item.url}`;
              if (wantsSummary) {
                try {
                  const block = await pullSections(item.url);
                  ctx += `\n\nSource excerpt:\n${block}`;
                } catch (e) {
                  console.warn('section fetch failed', e?.message || e);
                }
              }
            } else {
              ctx = `No exact match for Clarification ${num}-${yr}. Available for ${yr}: ` +
                list.map((it) => `${it.title}`).join(', ');
            }
          }
          // Case C: latest ask
          else if (latestAsk) {
            const y = data.years?.[0];
            const latest = y ? data.clarifications?.[y]?.slice(-1)[0] : null;
            if (latest) {
              ctx = `Latest clarification: ${latest.title} (${y}). URL: ${latest.url}`;
              if (wantsSummary) {
                try {
                  const block = await pullSections(latest.url);
                  ctx += `\n\nSource excerpt:\n${block}`;
                } catch (e) {
                  console.warn('section fetch failed', e?.message || e);
                }
              }
            }
          }
          // Case D: generic year mention (e.g., "2025 clarifications")
          else {
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

      const sofiaSystem = {
        role: 'system',
        content: [
          'You are Sofia, an expert Rugby Union referee coach.',
          'Be friendly and conversational—like texting a mentor.',
          '',
          // Clarifying
          'If the question is vague or likely depends on context, ask 1–2 short clarifying questions first. Keep them casual.',
          'Otherwise answer directly.',
          '',
          // Answering
          'Give a clear, concise ruling in plain language and naturally mention relevant Law numbers (e.g., “under Law 9.13”).',
          'When teaching or judgment could vary, optionally add a tiny section titled “Key considerations” with up to 3 bullets (only if helpful).',
          'Keep messages brief; avoid formal headings like Ruling/Law/Note.',
          '',
          // Scope
          'Never answer non-rugby questions.',
        ].join('\n'),
      };

      const messagesPayload = extraSystem
        ? [sofiaSystem, extraSystem, ...userMessages]
        : [sofiaSystem, ...userMessages];

      const response = await openai.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4o',
        messages: messagesPayload,
        max_tokens: 300,
        temperature: 0.6,
      });

      res.json({ reply: response.choices[0].message.content });
    } catch (err) {
      console.error('OpenAI API error:', err);
      res.status(500).send('Error communicating with OpenAI');
    }
  }
);
