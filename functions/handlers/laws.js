const { onRequest } = require('firebase-functions/v2/https');
const axios = require('axios');
const cheerio = require('cheerio');

let Firestore;
try {
  Firestore = require('@google-cloud/firestore').Firestore;
} catch (e) {
  console.warn('Firestore SDK not installed. Run: npm i @google-cloud/firestore');
}
const firestore = Firestore ? new Firestore() : null;

// Ingestors
const { ingestAllLaws } = require('../scraper/lawsIngest');
const { ingestSupplements } = require('../scraper/supplementsIngest');

// ---------------- Ingest World Rugby Laws ----------------
exports.ingestLaws = onRequest(
  { region: 'us-central1', timeoutSeconds: 540, memory: '512MiB' },
  async (req, res) => {
    try {
      const version = (req.query.version || '2025.0').toString();
      const result = await ingestAllLaws(version);
      res.json({ ok: true, ...result });
    } catch (err) {
      console.error('ingestLaws error:', err);
      res.status(500).json({ ok: false, error: err?.message || String(err) });
    }
  }
);

// ---------------- Ingest Supplements (GLDO, GMGs, etc.) ----------------
exports.ingestSupplements = onRequest(
  { region: 'us-central1', timeoutSeconds: 180, memory: '512MiB' },
  async (req, res) => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ ok: false, error: 'Use POST with JSON body.' });
      }

      const version  = (req.query.version  || req.body?.version  || '2025.0').toString();
      const category = (req.query.category || req.body?.category || 'guideline').toString();
      const items    = Array.isArray(req.body?.items) ? req.body.items : [];

      if (!items.length) {
        return res.status(400).json({ ok: false, error: 'items (array of chunks) is required' });
      }

      // Optional cap
      const limited = items.slice(0, 50);

      // ✅ pass (version, category, items)
      const result = await ingestSupplements(version, category, limited);
      res.json(result);
    } catch (err) {
      console.error('ingestSupplements error:', err);
      res.status(500).json({ ok: false, error: err?.message || String(err) });
    }
  }
);


// ---------------- Search ----------------
exports.lawsSearch = onRequest(
  { region: 'us-central1', timeoutSeconds: 30, memory: '256MiB', cors: true },
  async (req, res) => {
    if (!firestore) return res.status(500).json({ error: 'Firestore unavailable' });

    const q = String(req.query.q || '').trim();
    const version = (req.query.version || '2025.0').toString();
    if (!q) return res.status(400).json({ error: 'q required' });

    try {
      const snap = await firestore.collection(`laws/${version}/chunks`).limit(500).get();
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
        .slice(0, 5)
        .map(({ it, score }) => ({
          score: Number(score.toFixed(2)),
          lawRef: it.lawRef,
          sectionTitle: it.sectionTitle,
          sourceUrl: it.sourceUrl,
          snippet: it.text.length > 300 ? it.text.slice(0, 300) + '…' : it.text,
        }));

      res.json({ q, version, results: scored });
    } catch (e) {
      console.error('lawsSearch error:', e);
      res.status(500).json({ error: 'search failed' });
    }
  }
);

function escapeRe(s) {
  // fixed character class
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// ---------------- Probe (debug) ----------------
exports.lawsFetchProbe = onRequest(
  { region: 'us-central1', timeoutSeconds: 30, memory: '256MiB' },
  async (req, res) => {
    const url = String(req.query.url || '');
    if (!url) return res.status(400).json({ ok: false, error: 'url is required' });

    try {
      const { data: html } = await axios.get(url, {
        headers: { 'User-Agent': 'RefereeIQ Bot (axios)', 'Accept-Language': 'en-US,en;q=0.9' },
        timeout: 20000,
      });

      const $ = cheerio.load(html);
      const title =
        $('h1, .page-title, header h1').first().text().trim() ||
        $('title').first().text().trim();

      const sample =
        $('.law, .content, article, main, .region-content, .rich-text, .page-content')
          .text().replace(/\s+/g, ' ').trim().slice(0, 800) ||
        $('body').text().replace(/\s+/g, ' ').trim().slice(0, 800);

      res.json({ ok: true, title, sample, length: sample.length });
    } catch (e) {
      res.status(500).json({ ok: false, error: String(e) });
    }
  }
);
