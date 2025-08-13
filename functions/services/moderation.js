// functions/services/moderation.js
const { getAIConfig } = require('../config/ai');

async function moderateText(text, apiKey) {
  if (!text || !text.trim()) {
    return { flagged: false, categories: {}, category_scores: {} };
  }

  const { moderation } = await getAIConfig();
  const model = moderation?.model || 'omni-moderation-latest';

  const res = await fetch('https://api.openai.com/v1/moderations', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model, input: text }),
  });

  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Moderation HTTP ${res.status}: ${t}`);
  }

  const data = await res.json();
  const result = data.results?.[0] || {};
  return {
    flagged: !!result.flagged,
    categories: result.categories || {},
    category_scores: result.category_scores || {},
  };
}

module.exports = { moderateText };
