/**
 * When users/{userId} is deleted (e.g. account deletion), remove orphaned user data.
 * Client deletes the profile doc first; this trigger completes cleanup server-side.
 *
 * Uses Firebase Functions **v1** Firestore triggers (not Gen2/Eventarc) to avoid
 * regional Eventarc permission errors some projects hit when deploying Gen2 document triggers.
 */

const functions = require('firebase-functions/v1');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');

try {
  admin.app();
} catch {
  admin.initializeApp();
}

/**
 * Delete docs matching field == value in batches (Firestore batch max 500 ops).
 */
async function deleteWhereEquals(collectionName, field, value, batchSize = 450) {
  const db = admin.firestore();
  let total = 0;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await db.collection(collectionName).where(field, '==', value).limit(batchSize).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    total += snap.size;
  }
  return total;
}

exports.cleanupUserDataOnProfileDeleted = functions
  .region('us-central1')
  .runWith({ timeoutSeconds: 300, memory: '512MB' })
  .firestore.document('users/{userId}')
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;
    logger.info('cleanupUserDataOnProfileDeleted started', { userId });

    try {
      const n = await deleteWhereEquals('query_history', 'uid', userId);
      logger.info('cleanup query_history', { userId, deleted: n });
    } catch (e) {
      logger.error('cleanup query_history failed', { userId, error: e?.message });
    }

    try {
      const n = await deleteWhereEquals('challenge_attempts', 'uid', userId);
      logger.info('cleanup challenge_attempts', { userId, deleted: n });
    } catch (e) {
      logger.error('cleanup challenge_attempts failed', { userId, error: e?.message });
    }

    try {
      const n = await deleteWhereEquals('sofia_chat_cache', 'uid', userId);
      logger.info('cleanup sofia_chat_cache', { userId, deleted: n });
    } catch (e) {
      logger.error('cleanup sofia_chat_cache failed', { userId, error: e?.message });
    }

    try {
      await admin.firestore().collection('leaderboard').doc(userId).delete();
      logger.info('cleanup leaderboard doc', { userId });
    } catch (e) {
      logger.warn('cleanup leaderboard failed', { userId, error: e?.message });
    }

    try {
      const bucket = admin.storage().bucket();
      await bucket.file(`profile_pics/${userId}.jpg`).delete({ ignoreNotFound: true });
      const [files] = await bucket.getFiles({ prefix: `profile_pics/${userId}/` });
      await Promise.all(files.map((f) => f.delete().catch(() => {})));
      logger.info('cleanup storage profile_pics', { userId, extraFiles: files.length });
    } catch (e) {
      logger.warn('cleanup storage failed', { userId, error: e?.message });
    }

    logger.info('cleanupUserDataOnProfileDeleted finished', { userId });
  });
