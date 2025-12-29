// functions/index.js
// Gen2 Firebase Functions (Node 20)

// Handlers
const { chatWithGPT } = require('./handlers/chat');
const {
  scrapeClarifications,
  clarificationsLatest,
  clarificationText,
} = require('./handlers/clarifications');
const { pingV2 } = require('./handlers/health');

// Scheduled tasks
const { clarificationsNotify } = require('./tasks/clarificationsNotify');

// Daily challenge tasks
const {
  createDailyChallenge,
  createDailyChallengeNow,
} = require('./tasks/createDailyChallenge');

// Laws + Supplements handlers
const {
  ingestLaws,
  lawsSearch,
  lawsFetchProbe,
  ingestSupplements,
} = require('./handlers/laws');

// ---------------- Export handlers ----------------
exports.chatWithGPT = chatWithGPT;
exports.scrapeClarifications = scrapeClarifications;
exports.clarificationsLatest = clarificationsLatest;
exports.clarificationText = clarificationText;
exports.pingV2 = pingV2;

// ---------------- Export scheduled tasks ----------------
exports.clarificationsNotify = clarificationsNotify;

// ---------------- Export daily challenge tasks ----------------
exports.createDailyChallenge = createDailyChallenge;         // scheduled
exports.createDailyChallengeNow = createDailyChallengeNow;   // HTTP "run now"

// ---------------- Export laws + supplements ----------------
exports.ingestLaws = ingestLaws;
exports.lawsSearch = lawsSearch;
exports.lawsFetchProbe = lawsFetchProbe;
exports.ingestSupplements = ingestSupplements;
