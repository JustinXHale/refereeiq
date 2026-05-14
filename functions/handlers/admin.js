/**
 * Callable admin API — edits app_config/* via Admin SDK only.
 * Allowlist: Firestore doc app_config/admins { uids: string[] }
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

try {
  admin.app();
} catch {
  admin.initializeApp();
}

const REGION = 'us-central1';
const ADMINS_PATH = 'app_config/admins';
const MAX_ADMINS = 20;

const FEATURE_KEYS = new Set(['challengeEnabled', 'sourcesEnabled', 'shopEnabled']);
const PROMPT_KEYS = new Set(['sofiaSystem', 'challengeSystem', 'verifySystem']);
const AI_TOP_KEYS = new Set(['activeProvider', 'providers', 'challenge', 'sofiaChat', 'moderation', '_note']);

function db() {
  return admin.firestore();
}

async function getAdminUids() {
  const snap = await db().doc(ADMINS_PATH).get();
  if (!snap.exists) return [];
  const uids = snap.data()?.uids;
  return Array.isArray(uids) ? uids.filter((u) => typeof u === 'string' && u.length > 0) : [];
}

function requireAuth(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required');
  return uid;
}

async function requireAdmin(request) {
  const uid = requireAuth(request);
  const uids = await getAdminUids();
  if (!uids.includes(uid)) throw new HttpsError('permission-denied', 'Not authorized');
  return uid;
}

const SENSITIVE_KEY_RE = /api[_-]?key|^(client_)?secret$|^password$|^private[_-]?key$/i;

/** Remove sensitive-looking keys from AI config before returning to client. */
function sanitizeAiForClient(data) {
  if (!data || typeof data !== 'object') return {};
  const clone = JSON.parse(JSON.stringify(data));
  const strip = (obj) => {
    if (!obj || typeof obj !== 'object') return;
    if (Array.isArray(obj)) {
      obj.forEach(strip);
      return;
    }
    for (const k of Object.keys(obj)) {
      if (SENSITIVE_KEY_RE.test(k)) {
        delete obj[k];
      } else {
        strip(obj[k]);
      }
    }
  };
  strip(clone);
  return clone;
}

exports.adminGetConfig = onCall({ region: REGION }, async (request) => {
  requireAuth(request);
  const uids = await getAdminUids();
  const isAdmin = uids.includes(request.auth.uid);

  if (!isAdmin) {
    return { isAdmin: false };
  }

  const [featuresSnap, aiSnap, promptsSnap] = await Promise.all([
    db().doc('app_config/features').get(),
    db().doc('app_config/ai').get(),
    db().doc('app_config/prompts').get(),
  ]);

  return {
    isAdmin: true,
    adminUids: uids,
    features: featuresSnap.exists ? featuresSnap.data() || {} : {},
    ai: sanitizeAiForClient(aiSnap.exists ? aiSnap.data() || {} : {}),
    prompts: promptsSnap.exists ? promptsSnap.data() || {} : {},
  };
});

exports.adminUpdateFeatures = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);
  const patch = request.data?.patch;
  if (!patch || typeof patch !== 'object') {
    throw new HttpsError('invalid-argument', 'patch object required');
  }
  const updates = {};
  for (const k of Object.keys(patch)) {
    if (!FEATURE_KEYS.has(k)) {
      throw new HttpsError('invalid-argument', `Unknown field: ${k}`);
    }
    if (typeof patch[k] !== 'boolean') {
      throw new HttpsError('invalid-argument', `${k} must be boolean`);
    }
    updates[k] = patch[k];
  }
  if (Object.keys(updates).length === 0) {
    throw new HttpsError('invalid-argument', 'No valid fields');
  }
  await db().doc('app_config/features').set(updates, { merge: true });
  return { ok: true };
});

exports.adminUpdatePrompts = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);
  const patch = request.data?.patch;
  if (!patch || typeof patch !== 'object') {
    throw new HttpsError('invalid-argument', 'patch object required');
  }
  const updates = {};
  for (const k of Object.keys(patch)) {
    if (!PROMPT_KEYS.has(k)) {
      throw new HttpsError('invalid-argument', `Unknown field: ${k}`);
    }
    if (typeof patch[k] !== 'string') {
      throw new HttpsError('invalid-argument', `${k} must be string`);
    }
    updates[k] = patch[k];
  }
  if (Object.keys(updates).length === 0) {
    throw new HttpsError('invalid-argument', 'No valid fields');
  }
  await db().doc('app_config/prompts').set(updates, { merge: true });
  return { ok: true };
});

exports.adminUpdateAi = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);
  const patch = request.data?.patch;
  if (!patch || typeof patch !== 'object') {
    throw new HttpsError('invalid-argument', 'patch object required');
  }
  const updates = {};
  for (const k of Object.keys(patch)) {
    if (!AI_TOP_KEYS.has(k)) {
      throw new HttpsError('invalid-argument', `Unknown field: ${k}`);
    }
    updates[k] = patch[k];
  }
  if (Object.keys(updates).length === 0) {
    throw new HttpsError('invalid-argument', 'No valid fields');
  }
  await db().doc('app_config/ai').set(updates, { merge: true });
  return { ok: true };
});

exports.adminListAdmins = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);
  const uids = await getAdminUids();
  return { uids };
});

exports.adminAddAdmin = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);
  const newUid = String(request.data?.uid || '').trim();
  if (!newUid || newUid.length > 128) {
    throw new HttpsError('invalid-argument', 'Invalid uid');
  }
  let uids = await getAdminUids();
  if (uids.includes(newUid)) {
    return { uids };
  }
  if (uids.length >= MAX_ADMINS) {
    throw new HttpsError('resource-exhausted', `Max ${MAX_ADMINS} admins`);
  }
  uids = [...uids, newUid];
  await db().doc(ADMINS_PATH).set({ uids }, { merge: true });
  return { uids };
});

exports.adminRemoveAdmin = onCall({ region: REGION }, async (request) => {
  const callerUid = await requireAdmin(request);
  const removeUid = String(request.data?.uid || '').trim();
  if (!removeUid) {
    throw new HttpsError('invalid-argument', 'uid required');
  }
  let uids = await getAdminUids();
  if (!uids.includes(removeUid)) {
    return { uids };
  }
  if (uids.length <= 1) {
    throw new HttpsError('failed-precondition', 'Cannot remove the last admin');
  }
  uids = uids.filter((u) => u !== removeUid);
  await db().doc(ADMINS_PATH).set({ uids }, { merge: true });
  if (removeUid === callerUid) {
    return { uids, selfRemoved: true };
  }
  return { uids };
});
