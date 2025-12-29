// functions/scraper/supplementsIngest.js
let Firestore;
try { Firestore = require('@google-cloud/firestore').Firestore; }
catch (e) { console.warn('Firestore SDK not installed. Run: npm i @google-cloud/firestore'); }

const firestore = Firestore ? new Firestore() : null;

// super-rough token estimate
function approxTokens(str = '') {
  const words = String(str).trim().split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.round(words * 1.3));
}

/**
 * Ingest an array of supplemental chunks into laws/{version}/chunks
 * items: [{ lawRef, sectionTitle, text, sourceUrl, aliases? }]
 * category: e.g. "supplemental" | "guideline"
 */
async function ingestSupplements(version = '2025.0', category = 'supplemental', items = []) {
  if (!firestore) throw new Error('Firestore unavailable');
  if (!Array.isArray(items) || items.length === 0) {
    return { ok: true, version, inserted: 0, skipped: 0 };
  }

  const col = firestore.collection(`laws/${version}/chunks`);
  let inserted = 0, skipped = 0;

  for (const it of items) {
    const lawRef = (it.lawRef || 'Guidance').trim();
    const sectionTitle = (it.sectionTitle || 'Untitled').trim();
    const text = (it.text || '').trim();
    const sourceUrl = (it.sourceUrl || `local://${category}`).trim();
    const aliases = Array.isArray(it.aliases) ? it.aliases : [];

    if (!text) { skipped++; continue; }

    const doc = {
      lawRef,
      sectionTitle,
      text,
      sourceUrl,
      category,                 // <— tag for search/filter
      aliases,
      tokens: approxTokens(text),
      createdAt: new Date().toISOString(),
    };

    await col.add(doc);
    inserted++;
  }

  return { ok: true, version, inserted, skipped };
}

module.exports = { ingestSupplements };
