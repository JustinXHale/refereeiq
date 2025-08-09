// functions/handlers/health.js
const { onRequest } = require('firebase-functions/v2/https');

// Simple health check endpoint
// Returns "ok" + current timestamp if the service is running
exports.pingV2 = onRequest(
  { region: 'us-central1' },
  (req, res) => {
    res.status(200).send('ok ' + new Date().toISOString());
  }
);
