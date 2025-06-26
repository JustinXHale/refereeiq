// lib/services/profile_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profanity_filter/profanity_filter.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection name
  static const String _collection = 'users';

  // Save or update user profile
  static Future<void> saveProfile({
    required String userId,
    required String displayName,
    required String email,
    required String affiliation,
    required String affiliationDetail,
  }) async {
    // Profanity check
    final filter = ProfanityFilter();
    if (filter.hasProfanity(displayName)) {
      throw Exception('Display name contains inappropriate language.');
    }

    await _firestore.collection(_collection).doc(userId).set({
      'displayName': displayName,
      'email': email,
      'affiliation': affiliation,
      'affiliationDetail': affiliationDetail,
      'totalPoints': 0, // initial score
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Load user profile
  static Future<Map<String, dynamic>?> loadProfile(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (doc.exists) {
      return doc.data();
    } else {
      return null;
    }
  }

  // Update user score (example: add daily challenge score)
  static Future<void> updatePoints({
    required String userId,
    required int pointsToAdd,
  }) async {
    final docRef = _firestore.collection(_collection).doc(userId);

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      final currentPoints = docSnapshot.get('totalPoints') ?? 0;
      transaction.update(docRef, {
        'totalPoints': currentPoints + pointsToAdd,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get leaderboard (top N users by totalPoints)
  static Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'displayName': data['displayName'] ?? '',
        'totalPoints': data['totalPoints'] ?? 0,
      };
    }).toList();
  }
}
