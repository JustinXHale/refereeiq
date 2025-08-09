// functions/scraper/parse.js

// Validate that a URL is a proper World Rugby clarification page
function validateClarificationUrl(raw) {
  try {
    const u = new URL(String(raw));
    if (u.protocol !== 'https:') return null;
    if (u.hostname !== 'passport.world.rugby') return null;

    // Accept both modern and pre-2018 paths, with or without trailing slash
    const endsWithClar = /\/clarification-\d{1,2}-\d{4}\/?$/i.test(u.pathname);
    const hasBase = /\/laws-of-the-game\/law-clarifications\//i.test(u.pathname);
    return endsWithClar && hasBase ? u.toString() : null;
  } catch {
    return null;
  }
}

// Extracts key sections like Request/Ruling/etc. from a clarification page (Cheerio instance required)
function extractClarificationSections($) {
  // Title: prefer H1, fallback to <title>
  const title = (
    $('h1').first().text() ||
    $('title').first().text() ||
    'Law Clarification'
  ).trim();

  // Headings we care about (case-insensitive, prefix match)
  const wanted = [
    'request',
    'ruling',
    'decision',
    'determination',
    'clarification',
    'law application guideline',
    'guideline',
    'question',
    'answer',
    'outcome',
    'sanction',
    'background',
    'context',
    'conclusion',
  ];

  // Reasonable root
  let root = $('article').first();
  if (!root.length) root = $('main').first();
  if (!root.length) root = $('body').first();

  const headingNodes = [];
  const isWanted = (txt) => {
    const t = String(txt || '').trim().toLowerCase();
    return wanted.some((w) => t.startsWith(w) || t === w);
  };

  // 1) Real headings
  root.find('h2, h3, h4').each((_, el) => {
    const txt = $(el).text().trim();
    if (isWanted(txt)) headingNodes.push(el);
  });

  // 2) Paragraphs whose first child is <strong>/<b> with a wanted heading
  root.find('p').each((_, el) => {
    const firstStrong = $(el).children('strong, b').first();
    if (!firstStrong.length) return;
    const strongText = firstStrong.text().trim();
    if (isWanted(strongText)) headingNodes.push(el);
  });

  // Dedup, preserve order
  const seenSet = new Set();
  const headings = headingNodes.filter((n) => {
    if (seenSet.has(n)) return false;
    seenSet.add(n);
    return true;
  });

  const headingSet = new Set(headings);

  const cleanText = (node) => {
    const $n = $(node);

    // Render simple tables into text rows
    if ($n.is('table')) {
      const rows = [];
      $n.find('tr').each((_, tr) => {
        const cols = [];
        $(tr).find('th,td').each((__, td) => cols.push($(td).text().trim()));
        if (cols.length) rows.push(cols.join(' | '));
      });
      return rows.join('\n');
    }

    // Generic block text cleanup
    return $n.text().replace(/\s+\n/g, '\n').trim();
  };

  const sections = [];

  headings.forEach((el) => {
    let headingText = $(el).text().trim();

    // If heading is a <p><strong>Heading</strong>...</p>, prefer the strong text
    const strong = $(el).children('strong, b').first();
    if (strong.length) headingText = strong.text().trim();

    const buf = [];
    let n = $(el).next();

    while (n.length && !headingSet.has(n.get(0))) {
      if (/^(script|style|nav|header|footer)$/i.test(n[0].tagName)) {
        n = n.next();
        continue;
      }
      if (/^(p|ul|ol|blockquote|div|table|figure)$/i.test(n[0].tagName)) {
        const t = cleanText(n[0]);
        if (t) buf.push(t);
      }
      n = n.next();
    }

    const text = buf.join('\n\n').trim();
    if (text) sections.push({ heading: headingText, text });
  });

  // Fallback: if nothing recognized, give a single big Content section
  if (sections.length === 0) {
    const rootText = root.text().trim();
    if (rootText) sections.push({ heading: 'Content', text: rootText.slice(0, 4000) });
  }

  return { title, sections };
}

module.exports = {
  validateClarificationUrl,
  extractClarificationSections,
};
