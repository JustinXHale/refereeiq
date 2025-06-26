import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getTodayLeaderboard() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _db
        .collection('leaderboard')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> saveScore(String uid, int score) async {
    await _db.collection('leaderboard').doc(uid).set({
      'score': score,
      'timestamp': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePlayerProfile(String uid, Map<String, dynamic> profile) async {
    await _db.collection('users').doc(uid).set(profile, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPlayerProfile(String uid) {
    return _db.collection('users').doc(uid).get();
  }
}
