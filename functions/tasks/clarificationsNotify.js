// functions/tasks/clarificationsNotify.js
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { fetchClarifications } = require('../scraper/scrape');
const { messaging, firestore } = require('../services/firebase');

const CLARIFICATIONS_TOPIC = 'law-clarifications';

exports.clarificationsNotify = onSchedule(
  {
    // Every Monday at 09:00 UTC
    schedule: '0 9 * * MON',
    timeZone: 'Etc/UTC',
    retryCount: 0,
    region: 'us-central1',
  },
  async () => {
    try {
      if (!messaging) {
        console.warn('Skipping FCM send — firebase-admin not installed. Run: npm i firebase-admin');
        return;
      }

      const data = await fetchClarifications();
      const years = data.years || [];
      if (!years.length) return;

      const y = years[0];
      const list = data.clarifications?.[y] || [];
      if (!list.length) return;

      // list sorted asc by number; newest is last
      const latest = list[list.length - 1];
      const currentKey = `${y}-${latest.number}`;

      // read/write lastKey in Firestore so we only notify on change
      let lastKey = null;
      try {
        if (firestore) {
          const docRef = firestore.doc('admin/clarifications');
          const snap = await docRef.get();
          lastKey = snap.exists ? snap.data().lastKey : null;

          if (lastKey !== currentKey) {
            await docRef.set(
              {
                lastKey: currentKey,
                lastTitle: latest.title,
                lastUrl: latest.url,
                updatedAt: new Date().toISOString(),
              },
              { merge: true }
            );
          }
        } else {
          console.warn('Skipping persistence — Firestore not installed');
        }
      } catch (e) {
        console.error('Persistence error:', e?.message || e);
      }

      if (lastKey === currentKey) {
        console.log('No new clarifications since last check');
        return;
      }

      // Send a topic push to FCM
      await messaging.send({
        topic: CLARIFICATIONS_TOPIC,
        notification: {
          title: latest.title,
          body: 'New World Rugby Law Clarification',
        },
        data: {
          year: String(y),
          number: String(latest.number),
          url: latest.url,
          title: latest.title,
        },
      });

      console.log(`Sent FCM to topic "${CLARIFICATIONS_TOPIC}" for ${latest.title}`);
    } catch (err) {
      console.error('clarificationsNotify error:', err);
    }
  }
);
