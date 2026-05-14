import 'package:cloud_functions/cloud_functions.dart';

/// Remote admin API (Cloud Functions). Must match [region] with deployed callables.
class AdminConfigSnapshot {
  const AdminConfigSnapshot({
    required this.isAdmin,
    this.adminUids = const [],
    this.features = const {},
    this.ai = const {},
    this.prompts = const {},
  });

  final bool isAdmin;
  final List<String> adminUids;
  final Map<String, dynamic> features;
  final Map<String, dynamic> ai;
  final Map<String, dynamic> prompts;
}

class AdminService {
  AdminService({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _fn;

  Future<AdminConfigSnapshot> getConfig() async {
    final result = await _fn.httpsCallable('adminGetConfig').call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final isAdmin = data['isAdmin'] == true;
    if (!isAdmin) {
      return const AdminConfigSnapshot(isAdmin: false);
    }
    return AdminConfigSnapshot(
      isAdmin: true,
      adminUids: List<String>.from(data['adminUids'] as List? ?? []),
      features: Map<String, dynamic>.from(data['features'] as Map? ?? {}),
      ai: Map<String, dynamic>.from(data['ai'] as Map? ?? {}),
      prompts: Map<String, dynamic>.from(data['prompts'] as Map? ?? {}),
    );
  }

  Future<void> updateFeatures(Map<String, dynamic> patch) async {
    await _fn.httpsCallable('adminUpdateFeatures').call(<String, dynamic>{
      'patch': patch,
    });
  }

  Future<void> updatePrompts(Map<String, dynamic> patch) async {
    await _fn.httpsCallable('adminUpdatePrompts').call(<String, dynamic>{
      'patch': patch,
    });
  }

  Future<void> updateAi(Map<String, dynamic> patch) async {
    await _fn.httpsCallable('adminUpdateAi').call(<String, dynamic>{
      'patch': patch,
    });
  }

  Future<List<String>> addAdmin(String uid) async {
    final result = await _fn.httpsCallable('adminAddAdmin').call(<String, dynamic>{
      'uid': uid,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return List<String>.from(data['uids'] as List? ?? []);
  }

  Future<({List<String> uids, bool selfRemoved})> removeAdmin(String uid) async {
    final result = await _fn.httpsCallable('adminRemoveAdmin').call(<String, dynamic>{
      'uid': uid,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return (
      uids: List<String>.from(data['uids'] as List? ?? []),
      selfRemoved: data['selfRemoved'] == true,
    );
  }
}
