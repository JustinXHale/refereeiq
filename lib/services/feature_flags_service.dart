import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureFlagsService {
  FeatureFlagsService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<bool> watchChallengeEnabled() {
    return _db.collection('app_config').doc('features').snapshots().map((snap) {
      final data = snap.data();
      return data?['challengeEnabled'] == true;
    });
  }

  Stream<bool> watchSourcesEnabled() {
    return _db.collection('app_config').doc('features').snapshots().map((snap) {
      final data = snap.data();
      return data?['sourcesEnabled'] == true;
    });
  }

  Stream<bool> watchShopEnabled() {
    return _db.collection('app_config').doc('features').snapshots().map((snap) {
      final data = snap.data();
      return data?['shopEnabled'] == true;
    });
  }
}
