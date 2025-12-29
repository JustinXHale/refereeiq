// functions/services/openai.js
const { defineSecret } = require('firebase-functions/params');
const OpenAI = require('openai');

const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');

function getOpenAI() {
  return new OpenAI({ apiKey: OPENAI_API_KEY.value() });
}

function getOpenAIKey() {
  return OPENAI_API_KEY.value();
}

const withOpenAISecret = { secrets: [OPENAI_API_KEY] };

module.exports = { getOpenAI, getOpenAIKey, withOpenAISecret };
