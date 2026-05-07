import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QueryHistoryEntry {
  final String id;
  final String query;
  final String response;
  final String queryType;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  QueryHistoryEntry({
    required this.id,
    required this.query,
    required this.response,
    required this.queryType,
    required this.timestamp,
    this.metadata,
  });

  factory QueryHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueryHistoryEntry(
      id: doc.id,
      query: data['query'] ?? '',
      response: data['response'] ?? '',
      queryType: data['query_type'] ?? 'chat',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}

class QueryHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get user's query history with pagination
  Stream<List<QueryHistoryEntry>> getUserHistory({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = _db
        .collection('query_history')
        .where('uid', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => QueryHistoryEntry.fromFirestore(doc))
          .toList();
    });
  }

  // Delete a single query history entry
  Future<void> deleteEntry(String entryId) async {
    await _db.collection('query_history').doc(entryId).delete();
  }

  // Delete all query history for current user
  Future<int> deleteAllForUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final snapshot = await _db
        .collection('query_history')
        .where('uid', isEqualTo: user.uid)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    return snapshot.docs.length;
  }

  // Get total count for user
  Future<int> getUserHistoryCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final snapshot = await _db
        .collection('query_history')
        .where('uid', isEqualTo: user.uid)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
