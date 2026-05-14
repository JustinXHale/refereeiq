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
const { incidentAnalyze, incidentRuling } = require('./handlers/incident');

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

const { cleanupUserDataOnProfileDeleted } = require('./handlers/userCleanup');
const {
  adminGetConfig,
  adminUpdateFeatures,
  adminUpdatePrompts,
  adminUpdateAi,
  adminListAdmins,
  adminAddAdmin,
  adminRemoveAdmin,
} = require('./handlers/admin');

// ---------------- Export handlers ----------------
exports.chatWithGPT = chatWithGPT;
exports.scrapeClarifications = scrapeClarifications;
exports.clarificationsLatest = clarificationsLatest;
exports.clarificationText = clarificationText;
exports.pingV2 = pingV2;
exports.incidentAnalyze = incidentAnalyze;
exports.incidentRuling = incidentRuling;

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

// ---------------- Account deletion cascade ----------------
exports.cleanupUserDataOnProfileDeleted = cleanupUserDataOnProfileDeleted;

// ---------------- Admin console (callable) ----------------
exports.adminGetConfig = adminGetConfig;
exports.adminUpdateFeatures = adminUpdateFeatures;
exports.adminUpdatePrompts = adminUpdatePrompts;
exports.adminUpdateAi = adminUpdateAi;
exports.adminListAdmins = adminListAdmins;
exports.adminAddAdmin = adminAddAdmin;
exports.adminRemoveAdmin = adminRemoveAdmin;
