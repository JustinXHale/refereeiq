// functions/services/aiProvider.js
//
// Provider-agnostic AI layer. Reads app_config/ai from Firestore and returns
// a configured OpenAI SDK client for whichever provider is active.
//
// To switch providers:
//   1. Edit app_config/ai.activeProvider in Firebase console
//   2. No code changes, no redeploy, no app update needed
//
// To add a new provider (e.g. litemaas):
//   1. firebase functions:secrets:set LITEMAAS_API_KEY
//   2. firebase deploy --only functions  (mounts the secret)
//   3. Add providers.litemaas config to app_config/ai in Firestore:
//        baseURL, chatModel, simpleChatModel, challengeModel, secretName, temperature
//   4. Set activeProvider: "litemaas" — live on next invocation, no redeploy needed

const OpenAI = require('openai');
const admin = require('firebase-admin');

// Fallback defaults for OpenAI only. All other providers (e.g. litemaas) must be
// fully configured in Firestore providers.{name} — no hardcoded model names.
const OPENAI_DEFAULTS = {
  baseURL: 'https://api.openai.com/v1',
  simpleChatModel: 'gpt-4o-mini',
  chatModel: 'gpt-4o',
  challengeModel: 'gpt-4o',
  temperature: { chat: 0.6, challenge: 0.4 },
};

/**
 * Reads app_config/ai from Firestore and returns a ready-to-use provider object.
 *
 * @param {Object} secretValues - Resolved secret values available to the calling function.
 *   Example: { OPENAI_API_KEY: 'sk-...' }
 *   When LiteMaaS is configured, also pass: { LITEMAAS_API_KEY: '...' }
 * @param {{ chatTier?: 'simple' | 'full' }} [options] - Sofia chat routing (default full).
 *
 * @returns {{
 *   client: OpenAI,
 *   models: { chat: string, challenge: string, chatTier: string },
 *   temperature: { chat: number, challenge: number },
 *   supportsStructuredOutputs: boolean
 * }}
 */
async function getAIProvider(secretValues, options = {}) {
  let cfg = {};
  try {
    const snap = await admin.firestore().doc('app_config/ai').get();
    if (snap.exists) cfg = snap.data() || {};
  } catch (e) {
    console.warn('aiProvider: failed to read app_config/ai, using defaults:', e?.message);
  }

  const activeProvider = cfg.activeProvider || 'openai';
  const defaults = activeProvider === 'openai' ? OPENAI_DEFAULTS : {};
  const raw = cfg.providers?.[activeProvider] || {};
  // Accept common alternate field names from consoles / docs (`model` vs `chatModel`).
  const providerCfg = {
    ...raw,
    chatModel: raw.chatModel || raw.model,
    simpleChatModel: raw.simpleChatModel || raw.simple_model,
    challengeModel: raw.challengeModel || raw.challenge_model,
  };

  const secretName = providerCfg.secretName || 'OPENAI_API_KEY';
  const apiKey = secretValues[secretName];

  if (activeProvider !== 'openai' && !String(apiKey || '').trim()) {
    throw new Error(
      `AI_CONFIG: Missing API key for secret "${secretName}". Set providers.${activeProvider}.secretName and bind that secret to the function.`,
    );
  }

  const clientOptions = { apiKey };
  const baseURL = providerCfg.baseURL || defaults.baseURL;
  if (baseURL) clientOptions.baseURL = baseURL;

  const chatTier = options.chatTier === 'simple' ? 'simple' : 'full';
  const simpleChatModel =
    providerCfg.simpleChatModel || defaults.simpleChatModel || defaults.chatModel;
  const fullChatModel = providerCfg.chatModel || defaults.chatModel;
  const resolvedChatModel = chatTier === 'simple' ? simpleChatModel : fullChatModel;

  if (activeProvider !== 'openai' && !String(resolvedChatModel || '').trim()) {
    throw new Error(
      `AI_CONFIG: providers.${activeProvider} must set chatModel (or model) in app_config/ai — required for OpenAI-compatible chat.`,
    );
  }

  const client = new OpenAI(clientOptions);

  return {
    client,
    models: {
      chat: resolvedChatModel,
      challenge:
        providerCfg.challengeModel
        || providerCfg.chatModel
        || defaults.challengeModel,
      chatTier,
    },
    temperature: {
      chat:      providerCfg.temperature?.chat      ?? defaults.temperature?.chat      ?? 0.6,
      challenge: providerCfg.temperature?.challenge ?? defaults.temperature?.challenge ?? 0.4,
    },
    // json_schema structured outputs are an OpenAI feature; other providers fall back to json_object
    supportsStructuredOutputs: activeProvider === 'openai',
  };
}

module.exports = { getAIProvider };
