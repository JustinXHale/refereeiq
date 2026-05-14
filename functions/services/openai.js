// functions/services/openai.js
const { defineSecret } = require('firebase-functions/params');
const OpenAI = require('openai');

const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');
const LITEMAAS_API_KEY = defineSecret('LITEMAAS_API_KEY');

function getOpenAI() {
  return new OpenAI({ apiKey: OPENAI_API_KEY.value() });
}

function getOpenAIKey() {
  return OPENAI_API_KEY.value();
}

function getLiteMaaSKey() {
  return LITEMAAS_API_KEY.value();
}

// Both secrets are declared so either provider can be activated via Firestore.
const withOpenAISecret = { secrets: [OPENAI_API_KEY, LITEMAAS_API_KEY] };

module.exports = { getOpenAI, getOpenAIKey, getLiteMaaSKey, withOpenAISecret };
