#!/usr/bin/env node
/**
 * One-time seed script — run after deploying Cloud Functions.
 *
 * Usage (from repo root):
 *   cd functions && node scripts/seed_firestore.js
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or an active `firebase login`.
 * The easiest way: `firebase use <your-project>` then run this script
 * via `firebase functions:shell` OR just run it directly with application-
 * default credentials if you've done `gcloud auth application-default login`.
 *
 * What it does:
 *  1. Writes app_config/prompts  — Sofia + challenge system prompts (editable forever after)
 *  2. Writes app_config/ai       — model/temperature defaults (only if doc doesn't exist yet)
 *  3. Writes app_config/features — feature flag defaults (only if doc doesn't exist yet)
 *
 * Safe to re-run: existing docs are NOT overwritten unless you pass --force.
 */

const admin = require('firebase-admin');
const { PROMPTS } = require('../config/ai');

const FORCE = process.argv.includes('--force');

// Init using application-default credentials + explicit project ID
if (!admin.apps.length) {
  admin.initializeApp({ projectId: 'refereeiq-69cff' });
}
const db = admin.firestore();

async function setDoc(path, data, { force = false, label } = {}) {
  const ref = db.doc(path);
  const snap = await ref.get();

  if (snap.exists && !force) {
    console.log(`  SKIP  ${path}  (already exists; pass --force to overwrite)`);
    return;
  }

  await ref.set(data, { merge: !force });
  console.log(`  WROTE ${path}`);
}

async function main() {
  console.log(`\nSeeding Firestore${FORCE ? ' (--force: overwriting existing docs)' : ''}...\n`);

  // 1. Prompts — these are the live editable values read by Cloud Functions
  await setDoc(
    'app_config/prompts',
    {
      sofiaSystem:      PROMPTS.sofiaChat.system,
      challengeSystem:  PROMPTS.challenge.system,
      verifySystem:     PROMPTS.verify.system,
      _seedVersion:     1,
      _note: 'Edit these fields in Firebase console to change Sofia\'s behavior without redeploying.',
    },
    { force: FORCE, label: 'Sofia + challenge prompts' },
  );

  // 2. AI config defaults (model/temperature) — only seed if missing
  await setDoc(
    'app_config/ai',
    {
      challenge:  { model: 'gpt-4o', temperature: 0.4 },
      sofiaChat:  { model: 'gpt-4o', temperature: 0.6 },
      moderation: { model: 'omni-moderation-latest', temperature: 0.0 },
      _note: 'Edit model/temperature here to switch LLMs without redeploying.',
    },
    { force: false, label: 'AI model config' },
  );

  // 3. Feature flags — only seed if missing
  await setDoc(
    'app_config/features',
    {
      challengeEnabled: true,
      sourcesEnabled:   true,
      shopEnabled:      false,
      _note: 'Toggle features here without an app release.',
    },
    { force: false, label: 'Feature flags' },
  );

  console.log('\nDone.\n');
  console.log('Next steps:');
  console.log('  1. firebase deploy --only functions');
  console.log('  2. Edit app_config/prompts in Firebase console whenever you want to tune Sofia.');
  console.log('  3. To set a manual challenge: write daily_challenges/YYYY-MM-DD-am');
  console.log('     with { manualOverride: true, questions: [...] }\n');
}

main().catch((e) => {
  console.error('Seed failed:', e);
  process.exit(1);
});
