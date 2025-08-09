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

  Stream<List<Map<String, dynamic>>> getLeaderboardFiltered({
    required String scoreType,
    String? state,
    String? affiliation,
  }) {
    Query query = _db.collection('leaderboard');

    if (state != null && state.isNotEmpty) {
      query = query.where('state', isEqualTo: state);
    }

    if (affiliation != null && affiliation.isNotEmpty) {
      query = query.where('type', isEqualTo: affiliation);
    }

    query = query.orderBy(scoreType, descending: true);

    return query.snapshots().map(
          (snapshot) =>
          snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList(),
    );
  }

  Future<void> submitScore({
    required String uid,
    required String name,
    required String state,
    required String type,
    required int score,
  }) async {
    final ref = _db.collection('leaderboard').doc(uid);
    await ref.set({
      'name': name,
      'state': state,
      'type': type,
      'daily': score,
      'monthly': FieldValue.increment(score),
      'lifetime': FieldValue.increment(score),
      'timestamp': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePlayerProfile(String uid, Map<String, dynamic> profile) async {
    await _db.collection('users').doc(uid).set(profile, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPlayerProfile(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  Future<List<String>> getAvailableStates() async {
    final snapshot = await _db.collection('leaderboard').get();

    final states = snapshot.docs
        .map((doc) => doc.data()['state'] as String?)
        .whereType<String>() // removes nulls and casts to non-nullable
        .toSet()
        .toList();

    return states;
  }
}
