import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------
  // Sign up / Sign in
  // -------------------------
  Future<User?> signUpWithEmail(String email,
      String password,
      Map<String, dynamic> profile,) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          ...profile,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'email': user.email,
            'name': user.displayName ?? '',
            'photoURL': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      if (kDebugMode) print('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // Optional: sign out of Google to avoid auto-pick next time
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get userChanges => _auth.authStateChanges();

  bool get isLoggedIn => _auth.currentUser != null;

  Future<void> saveUserProfile(String uid, Map<String, dynamic> profile) {
    return _db.collection('users').doc(uid).set(
        profile, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  // -------------------------
  // Delete Account (with re-auth)
  // -------------------------
  /// Deletes the signed-in user's account.
  /// - For password users: pass the current password.
  /// - For Google users: password can be null; we’ll re-auth via Google picker.
  ///
  /// Throws FirebaseAuthException on failures like 'requires-recent-login'.
  Future<void> deleteAccount({String? currentPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
          code: 'no-current-user', message: 'Not signed in.');
    }

    // 1) Re-authenticate
    await _reauthenticate(user, currentPassword: currentPassword);

    // 2) Delete profile doc (Cloud Function cleanupUserDataOnProfileDeleted removes
    //    query_history, challenge_attempts, sofia_chat_cache, leaderboard, Storage pics)
    final uid = user.uid;
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      if (kDebugMode) print('Warning: failed to delete users/$uid: $e');
    }
    try {
      await _db.collection('leaderboard').doc(uid).delete();
    } catch (e) {
      if (kDebugMode) print('Warning: failed to delete leaderboard/$uid: $e');
    }

    // 3) Delete auth user (this will sign them out server-side)
    await user.delete();

    // 4) Local cleanup
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  // -------------------------
  // Helpers
  // -------------------------
  Future<void> _reauthenticate(User user, {String? currentPassword}) async {
    final providers = user.providerData.map((p) => p.providerId).toList();
    final usesPassword = providers.contains('password');
    final usesGoogle = providers.contains('google.com');

    if (usesPassword) {
      final email = user.email;
      if (email == null ||
          (currentPassword == null || currentPassword.isEmpty)) {
        throw FirebaseAuthException(
          code: 'missing-credentials',
          message: 'Password required to delete this account.',
        );
      }
      final cred = EmailAuthProvider.credential(
          email: email, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      return;
    }

    if (usesGoogle) {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
            code: 'user-cancelled', message: 'Reauth cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(cred);
      return;
    }

    // Add other providers here (Apple, etc.) when needed
    throw FirebaseAuthException(
      code: 'unsupported-provider',
      message: 'Reauthentication for this provider is not implemented yet.',
    );
  }
}
