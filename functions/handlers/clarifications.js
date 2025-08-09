// functions/handlers/clarifications.js
const { onRequest } = require('firebase-functions/v2/https');
const axios = require('axios');
const cheerio = require('cheerio');

const { fetchClarifications } = require('../scraper/scrape');
const { validateClarificationUrl, extractClarificationSections } = require('../scraper/parse');

// ===============================
// HTTP: full clarifications JSON
// ===============================
const scrapeClarifications = onRequest(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB', cors: true },
  async (req, res) => {
    if (req.method !== 'GET') return res.status(405).json({ error: 'Use GET' });

    try {
      const data = await fetchClarifications();

      // Optional year filter: ?year=2025 or ?y=2025
      const yearParam = (req.query.year || req.query.y || '').toString().trim();
      if (yearParam) {
        const y = yearParam;
        const list = data.clarifications[y] || [];
        const filtered = {
          updatedAt: data.updatedAt,
          years: list.length ? [y] : [],
          clarifications: list.length ? { [y]: list } : {},
        };
        return res.json(filtered);
      }

      return res.json(data);
    } catch (err) {
      console.error('scrapeClarifications error:', err);
      return res.status(500).json({ error: 'Failed to scrape clarifications' });
    }
  }
);

// ==========================================
// HTTP: latest clarification (most recent yr)
// ==========================================
const clarificationsLatest = onRequest(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB', cors: true },
  async (req, res) => {
    if (req.method !== 'GET') return res.status(405).json({ error: 'Use GET' });

    try {
      const data = await fetchClarifications();
      const years = data.years || [];
      if (years.length === 0) {
        return res.json({ updatedAt: data.updatedAt, latest: null });
      }

      const y = years[0]; // years sorted desc
      const list = (data.clarifications?.[y] || []).slice();
      if (list.length === 0) {
        return res.json({ updatedAt: data.updatedAt, latest: null });
      }

      // list sorted by number asc; last item is newest for that year
      const latest = list[list.length - 1];

      return res.json({
        updatedAt: data.updatedAt,
        latest: { year: y, ...latest },
      });
    } catch (err) {
      console.error('clarificationsLatest error:', err);
      return res.status(500).json({ error: 'Failed to compute latest clarification' });
    }
  }
);

// ==============================================
// HTTP: single clarification text (title/sections)
// ==============================================
const clarificationText = onRequest(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB', cors: true },
  async (req, res) => {
    if (req.method !== 'GET') return res.status(405).json({ error: 'Use GET' });

    const rawUrl = (req.query.url || req.query.u || '').toString();
    const safeUrl = validateClarificationUrl(rawUrl);
    if (!safeUrl) return res.status(400).json({ error: 'Unsupported URL' });

    try {
      const { data: html } = await axios.get(safeUrl, {
        headers: {
          'User-Agent': 'RefereeIQ Bot (testing) - axios',
          'Accept-Language': 'en-US,en;q=0.9',
        },
        timeout: 20000,
      });

      const $ = cheerio.load(html);
      const { title, sections } = extractClarificationSections($);

      return res.json({ url: safeUrl, title, sections });
    } catch (err) {
      console.error('clarificationText error:', err?.message || err);
      return res.status(500).json({ error: 'Failed to fetch or parse clarification page' });
    }
  }
);

module.exports = {
  scrapeClarifications,
  clarificationsLatest,
  clarificationText,
};
