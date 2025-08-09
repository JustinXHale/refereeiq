// functions/scraper/scrape.js
const axios = require('axios');
const cheerio = require('cheerio');

// Simple in-memory cache (same behavior as your current code)
let _cache = { expires: 0, data: null };

async function fetchClarifications() {
  if (_cache.data && Date.now() < _cache.expires) return _cache.data;

  const url = 'https://passport.world.rugby/laws-of-the-game/law-clarifications/';
  const { data: html } = await axios.get(url, {
    headers: {
      'User-Agent': 'RefereeIQ Bot (testing) - axios',
      'Accept-Language': 'en-US,en;q=0.9',
    },
    timeout: 20000,
  });

  const $ = cheerio.load(html);

  // Collect links like "Clarification X-YYYY" and de-duplicate
  const items = [];
  const seen = new Set(); // key: `${year}-${number}-${href}`

  $('a').each((_, el) => {
    const text = $(el).text().trim().replace(/\s+/g, ' ');
    const match = /^Clarification\s+(\d+)\s*-\s*(\d{4})$/i.exec(text);
    if (!match) return;

    let href = $(el).attr('href');
    if (!href) return;
    href = href.startsWith('http') ? href : `https://passport.world.rugby${href}`;

    const number = match[1];
    const year = match[2];
    const key = `${year}-${number}-${href}`;
    if (seen.has(key)) return;
    seen.add(key);

    items.push({
      year,
      number,
      title: `Clarification ${number}-${year}`,
      url: href,
    });
  });

  // Group by year and sort by number; dedupe within each year
  const byYear = {};
  for (const it of items) {
    byYear[it.year] ??= [];
    byYear[it.year].push({ number: it.number, title: it.title, url: it.url });
  }
  for (const y of Object.keys(byYear)) {
    const yearSeen = new Set(); // key: `${number}-${url}`
    byYear[y] = byYear[y]
      .sort((a, b) => Number(a.number) - Number(b.number))
      .filter((it) => {
        const k = `${it.number}-${it.url}`;
        if (yearSeen.has(k)) return false;
        yearSeen.add(k);
        return true;
      });
  }

  const years = Object.keys(byYear).sort((a, b) => Number(b) - Number(a));
  const result = { updatedAt: new Date().toISOString(), years, clarifications: byYear };

  // Cache for 7 days
  _cache = { expires: Date.now() + 7 * 24 * 60 * 60 * 1000, data: result };
  return result;
}

module.exports = { fetchClarifications };
