// functions/services/firebase.js

// ---- Firebase Admin (FCM) ----
let admin;
try {
  admin = require('firebase-admin');
  if (admin.apps.length === 0) admin.initializeApp();
} catch {
  console.warn('firebase-admin not installed; run: npm i firebase-admin');
}

const messaging = admin ? admin.messaging() : null;

// ---- Firestore (for small state) ----
let firestore;
try {
  const { Firestore } = require('@google-cloud/firestore');
  firestore = new Firestore();
} catch {
  console.warn('Firestore not installed; run: npm i @google-cloud/firestore');
}

module.exports = { admin, messaging, firestore };
