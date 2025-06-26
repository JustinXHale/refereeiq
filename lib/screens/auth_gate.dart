import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/welcome_screen.dart';
import '../screens/verify_email_screen.dart';      // You'll need to create this screen
import '../screens/complete_profile_screen.dart';
import '../main.dart'; // For HomeScreen

/// AuthGate decides which screen to show based on
/// 1) authentication status
/// 2) email verified
/// 3) profile completeness
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        // Not signed in
        if (user == null) {
          return const WelcomeScreen();
        }

        // Signed in but email not verified
        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        // Signed in & verified => load profile
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (ctx2, profSnap) {
            if (profSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (profSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Error loading profile: ${profSnap.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final data = profSnap.data?.data();
            final complete = data != null &&
                data.containsKey('favoriteTeam') &&
                data.containsKey('city') &&
                data.containsKey('state') &&
                data.containsKey('affiliation') &&
                (data['affiliation'] != 'Referee' || data.containsKey('refereeAssociation')) &&
                data.containsKey('photoURL');

            return complete
                ? const HomeScreen()
                : const CompleteProfileScreen();
          },
        );
      },
    );
  }
}
