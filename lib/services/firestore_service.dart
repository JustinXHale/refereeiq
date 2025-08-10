import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---- Helpers for periods ----
  String _currentBlockKey([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final block = now.hour < 12 ? 'am' : 'pm';
    return '$y-$m-$d-$block'; // e.g., 2025-08-10-am
  }

  String _currentMonthKey([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    return '$y-$m'; // e.g., 2025-08
  }

  // Optional: not used by the leaderboard tab anymore, but kept if you want it.
  Stream<List<Map<String, dynamic>>> getTodayLeaderboard() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _db
        .collection('leaderboard')
        .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) {
      final m = d.data();
      m['uid'] = d.id;
      return m;
    }).toList());
  }

  // Main source for your UI table
  Stream<List<Map<String, dynamic>>> getLeaderboardFiltered({
    required String scoreType,
    String? state,
    String? affiliation,
  }) {
    final allowed = {'daily', 'monthly', 'lifetime'};
    final orderField = allowed.contains(scoreType.trim()) ? scoreType.trim() : 'lifetime';

    Query<Map<String, dynamic>> query = _db.collection('leaderboard');

    if (state != null && state.isNotEmpty) {
      query = query.where('state', isEqualTo: state);
    }
    if (affiliation != null && affiliation.isNotEmpty) {
      query = query.where('type', isEqualTo: affiliation);
    }

    // Order by a known-good field, and cap results to keep UI snappy.
    query = query.orderBy(orderField, descending: true).limit(200);

    return query.snapshots().map(
          (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }

  // Transactional submit: resets daily/monthly when block/month changes, then increments all
  Future<void> submitScore({
    required String uid,
    required String name,
    required String state,
    required String type, // 'Referee' | 'Coach' | 'Player'
    required int score,
  }) async {
    final docRef = _db.collection('leaderboard').doc(uid);
    final now = DateTime.now();
    final blockKey = _currentBlockKey(now);
    final monthKey = _currentMonthKey(now);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      int daily = 0;
      int monthly = 0;
      int lifetime = 0;
      String? lastBlockKey;
      String? lastMonthKey;

      if (snap.exists) {
        final data = snap.data()!;
        daily = (data['daily'] ?? 0) as int;
        monthly = (data['monthly'] ?? 0) as int;
        lifetime = (data['lifetime'] ?? 0) as int;
        lastBlockKey = data['lastBlockKey'] as String?;
        lastMonthKey = data['lastMonthKey'] as String?;
      }

      // Reset daily if we've entered a new block
      if (lastBlockKey != blockKey) {
        daily = 0;
      }
      // Reset monthly if we've entered a new month
      if (lastMonthKey != monthKey) {
        monthly = 0;
      }

      daily += score;
      monthly += score;
      lifetime += score;

      tx.set(docRef, {
        'name': name,
        'state': state,
        'type': type,
        'daily': daily,
        'monthly': monthly,
        'lifetime': lifetime,
        'lastBlockKey': blockKey,
        'lastMonthKey': monthKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<int> getRankForCurrentBlock({
    required String uid,
    String? state,        // optional filter
    String? affiliation,  // optional filter
  }) async {
    final docRef = _db.collection('leaderboard').doc(uid);
    final snap = await docRef.get();
    if (!snap.exists) return 1;

    final me = snap.data()!;
    final int myDaily = (me['daily'] ?? 0) as int;
    final int myLifetime = (me['lifetime'] ?? 0) as int;

    Query<Map<String, dynamic>> base = _db.collection('leaderboard');
    if (state != null && state.isNotEmpty) {
      base = base.where('state', isEqualTo: state);
    }
    if (affiliation != null && affiliation.isNotEmpty) {
      base = base.where('type', isEqualTo: affiliation);
    }

    // Count strictly higher daily
    final int higherDailyCount = (await base
        .where('daily', isGreaterThan: myDaily)
        .count()
        .get())
        .count ?? 0;

    // Tie-breaker: same daily, higher lifetime
    final int tieBreakerCount = (await base
        .where('daily', isEqualTo: myDaily)
        .where('lifetime', isGreaterThan: myLifetime)
        .count()
        .get())
        .count ?? 0;

    return higherDailyCount + tieBreakerCount + 1;
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
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return states;
  }
}

