// functions/scraper/lawsIngest.js
// Auto-discover and ingest World Rugby "Laws by number" pages into Firestore.
// Collection: laws/{version}/chunks
//
// Fields: {
//   lawRef:          "Law 18",
//   sectionTitle:    "Touch, quick throw and lineout – Quick throw",
//   text:            "<chunked paragraph text>",
//   sourceUrl:       "https://passport.world.rugby/laws-of-the-game/laws-by-number/18-touch-quick-throw-and-lineout/",
//   tokens:          <approx token count>,
//   aliases:         ["quick throw", "lineout"],   // light hints (best-effort)
//   order:           <monotonic number so we keep original sequence>
// }

const axios = require('axios');
const cheerio = require('cheerio');

let Firestore;
try {
  Firestore = require('@google-cloud/firestore').Firestore;
} catch (e) {
  // Deployed environment will have it; local dev might not.
}
const firestore = Firestore ? new Firestore() : null;

const BASE_INDEX =
  'https://passport.world.rugby/laws-of-the-game/laws-by-number/';

const USER_AGENT = 'RefereeIQ Bot (axios) - ingestion';
const REQ_HEADERS = {
  'User-Agent': USER_AGENT,
  'Accept-Language': 'en-US,en;q=0.9',
};

/** Small helper: wait between requests to be polite */
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Rough token estimate (OpenAI-ish) */
function approxTokens(str) {
  return Math.ceil((str || '').length / 4);
}

/** Build a Firestore doc id that’s stable and unique-ish */
function idFrom(url, idx) {
  const safe = url.replace(/[^a-z0-9]+/gi, '-').replace(/(^-|-$)/g, '').toLowerCase();
  return `${safe}-${idx}`.slice(0, 1500);
}

/** Try to derive "Law XX" + a readable title from the URL and page content */
function deriveLawRef(url, $) {
  try {
    const u = new URL(url);
    const segs = u.pathname.split('/').filter(Boolean);
    const slug = segs[segs.length - 1];

    let num = (slug.match(/^(\d{1,3})[-_]/) || [null, null])[1];
    const h1 = $('h1, .page-title, header h1').first().text().trim();
    if (!num) {
      const m = (h1 || '').match(/\bLaw\s+(\d{1,3})\b/i);
      if (m) num = m[1];
    }

    let title = h1 || slug.replace(/[-_]+/g, ' ');
    title = title.replace(/^\s*Law\s+\d{1,3}\s*[-.:–—]\s*/i, '').trim();

    return {
      lawRef: num ? `Law ${num}` : 'Law',
      lawTitle: title.charAt(0).toUpperCase() + title.slice(1),
    };
  } catch {
    return { lawRef: 'Law', lawTitle: '' };
  }
}

/** Pull the index, collect all law URLs */
async function discoverLawUrls() {
  const { data: html } = await axios.get(BASE_INDEX, { headers: REQ_HEADERS, timeout: 20000 });
  const $ = cheerio.load(html);

  const urls = new Set();
  $('a[href]').each((_, a) => {
    const href = $(a).attr('href') || '';
    if (!href.includes('/laws-by-number/')) return;
    if (/\/laws-by-number\/\d{1,3}-/.test(href)) {
      const abs = href.startsWith('http') ? href : new URL(href, BASE_INDEX).toString();
      urls.add(abs.replace(/#.*$/, ''));
    }
  });

  return [...urls].sort((a, b) => {
    const na = Number((a.match(/\/laws-by-number\/(\d{1,3})[-_]/) || [,'999'])[1]);
    const nb = Number((b.match(/\/laws-by-number\/(\d{1,3})[-_]/) || [,'999'])[1]);
    return na - nb;
  });
}

/** Extract content from a law page into structured sections and chunks */
function extractSectionsFromLawPage(url, html) {
  const $ = cheerio.load(html);
  const { lawRef, lawTitle } = deriveLawRef(url, $);

  const container =
    $('main, article, .content, .page-content, .region-content, .rich-text, .law')
      .first();
  const scope = container.length ? container : $('body');

  const sections = [];
  let current = { heading: '', blocks: [] };

  scope.find('h2, h3, p, li').each((_, el) => {
    const tag = el.tagName?.toLowerCase?.() || $(el).prop('tagName')?.toLowerCase?.() || '';
    const text = $(el).text().replace(/\s+/g, ' ').trim();
    if (!text) return;

    if (tag === 'h2' || tag === 'h3') {
      if (current.blocks.length) sections.push(current);
      current = { heading: text, blocks: [] };
    } else if (tag === 'p' || tag === 'li') {
      current.blocks.push(text);
    }
  });
  if (current.blocks.length) sections.push(current);

  if (!sections.length) {
    const bodyText = scope.text().replace(/\s+/g, ' ').trim();
    if (bodyText) {
      sections.push({ heading: lawTitle || 'Law text', blocks: [bodyText] });
    }
  }

  const MAX_CHARS = 1200;
  const chunks = [];
  let ordinal = 0;

  for (const sec of sections) {
    const secTitle = sec.heading || lawTitle || lawRef;
    let buffer = '';

    const flush = () => {
      const text = buffer.trim();
      if (!text) return;
      chunks.push({
        lawRef,
        sectionTitle: secTitle,
        text,
        sourceUrl: url,
        tokens: approxTokens(text),
        aliases: makeAliases(lawRef, secTitle),
        order: ordinal++,
      });
      buffer = '';
    };

    for (const block of sec.blocks) {
      if ((buffer + ' ' + block).length > MAX_CHARS) {
        flush();
        buffer = block;
      } else {
        buffer = buffer ? buffer + '\n' + block : block;
      }
    }
    flush();
  }

  return chunks;
}

/** Simple alias hints */
function makeAliases(lawRef, sectionTitle) {
  const a = [];
  const refNum = (lawRef.match(/\d+/) || [null])[0];
  if (refNum) a.push(`law ${refNum}`);

  const t = (sectionTitle || '').toLowerCase();
  if (t.includes('quick throw')) a.push('quick throw', 'lineout');
  if (t.includes('offside')) a.push('offside');
  if (t.includes('tackle')) a.push('tackle', 'ruck', 'jackal');
  if (t.includes('scrum')) a.push('scrum', 'front row', 'binding');
  if (t.includes('maul')) a.push('maul');
  if (t.includes('advantage')) a.push('advantage');
  if (t.includes('restart') || t.includes('kick-off')) a.push('kick-off', 'restart');

  return [...new Set(a)];
}

/** Ingest a single law page into Firestore */
async function ingestLawPage(version, url, idx) {
  const { data: html } = await axios.get(url, { headers: REQ_HEADERS, timeout: 25000 });
  const chunks = extractSectionsFromLawPage(url, html);
  if (!firestore) return { url, chunks: chunks.length };

  const batch = firestore.batch();
  const col = firestore.collection(`laws/${version}/chunks`);

  chunks.forEach((c, i) => {
    const id = idFrom(url, `${idx}-${i}`);
    batch.set(col.doc(id), c, { merge: true });
  });

  await batch.commit();
  return { url, chunks: chunks.length };
}

/** Public entry: discover all laws and ingest them */
async function ingestAllLaws(version = '2025.0') {
  if (!firestore) throw new Error('Firestore is unavailable in this environment');

  const col = firestore.collection(`laws/${version}/chunks`);
  const old = await col.limit(500).get();
  if (!old.empty) {
    const deletes = [];
    old.forEach((d) => deletes.push(col.doc(d.id).delete()));
    await Promise.all(deletes);
  }

  const urls = await discoverLawUrls();
  const results = [];
  let idx = 0;

  for (const url of urls) {
    try {
      const r = await ingestLawPage(version, url, idx++);
      results.push({ url, ok: true, chunks: r.chunks });
      await sleep(500);
    } catch (e) {
      results.push({ url, ok: false, error: String(e) });
    }
  }

  const pages = results.filter(r => r.ok).length;
  const chunks = results.filter(r => r.ok).reduce((sum, r) => sum + (r.chunks || 0), 0);
  return { version, pages, chunks, results };
}

/** Supplement ingestion (Game Management Guidelines, etc.) */
async function ingestSupplements(version = '2025.0', supplements = []) {
  if (!firestore) throw new Error('Firestore is unavailable in this environment');

  const col = firestore.collection(`supplements/${version}/chunks`);
  const old = await col.limit(500).get();
  if (!old.empty) {
    const deletes = [];
    old.forEach((d) => deletes.push(col.doc(d.id).delete()));
    await Promise.all(deletes);
  }

  const results = [];
  let idx = 0;

  for (const sup of supplements) {
    try {
      const { url, title } = sup;
      const { data: html } = await axios.get(url, { headers: REQ_HEADERS, timeout: 25000 });
      const chunks = extractSectionsFromLawPage(url, html).map(c => ({
        ...c,
        lawRef: 'Supplement',
        sectionTitle: `${title} — ${c.sectionTitle}`,
      }));

      const batch = firestore.batch();
      chunks.forEach((c, i) => {
        const id = idFrom(url, `${idx}-${i}`);
        batch.set(col.doc(id), c, { merge: true });
      });
      await batch.commit();

      results.push({ url, ok: true, chunks: chunks.length });
      idx++;
    } catch (e) {
      results.push({ url: sup.url, ok: false, error: String(e) });
    }
  }

  const pages = results.filter(r => r.ok).length;
  const chunks = results.filter(r => r.ok).reduce((sum, r) => sum + (r.chunks || 0), 0);
  return { version, pages, chunks, results };
}

module.exports = { ingestAllLaws, ingestSupplements };
