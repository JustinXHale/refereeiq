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

// Export handlers
exports.chatWithGPT = chatWithGPT;
exports.scrapeClarifications = scrapeClarifications;
exports.clarificationsLatest = clarificationsLatest;
exports.clarificationText = clarificationText;
exports.pingV2 = pingV2;

// Export scheduled tasks
exports.clarificationsNotify = clarificationsNotify;
