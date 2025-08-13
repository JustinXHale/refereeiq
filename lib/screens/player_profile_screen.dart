import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerProfileScreen extends StatelessWidget {
  final Map<String,
      dynamic> player; // expect at least: { uid: ..., name?: ..., lifetime?: ... }

  const PlayerProfileScreen({super.key, required this.player});

  Future<Map<String, dynamic>> _loadProfile() async {
    final uid = player['uid'] as String?;
    if (uid == null) return player;

    final snap = await FirebaseFirestore.instance.collection('users')
        .doc(uid)
        .get();
    final profile = snap.data() ?? {};

    return {
      ...player,
      // prefer Firestore profile, but fall back to what's on the leaderboard map
      'name': profile['name'] ?? player['name'],
      'photoURL': profile['photoURL'] ?? player['photoURL'] ?? player['image'],
      'favoriteTeam': profile['favoriteTeam'] ?? player['favoriteTeam'],
      'state': profile['state'] ?? player['state'],
      'affiliation': profile['affiliation'] ?? player['affiliation'] ??
          player['type'],
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RefereeIQ',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors
              .black),
        ),
        backgroundColor: colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? player;

          final name = (data['name'] ?? 'Unknown') as String;
          final photoURL = data['photoURL'] as String?;
          final favoriteTeam = data['favoriteTeam'] as String?;
          final state = data['state'] as String?;
          final affiliation = (data['affiliation'] ??
              data['type']) as String?; // keep compatibility
          final lifetime = data['lifetime'] ?? 0;

          ImageProvider? avatarImage;
          if (photoURL != null && photoURL.startsWith('http')) {
            avatarImage = NetworkImage(photoURL);
          }

          String initials() {
            final parts = name.trim().split(RegExp(r'\s+'));
            if (parts.isEmpty) return '?';
            if (parts.length == 1) return parts.first.isNotEmpty
                ? parts.first[0].toUpperCase()
                : '?';
            return (parts.first[0] + parts.last[0]).toUpperCase();
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 32.0, horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: avatarImage,
                    backgroundColor: Colors.grey.shade200,
                    child: avatarImage == null
                        ? Text(initials(), style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700))
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Text(name, style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  _line('Location', state ?? 'N/A'),
                  const SizedBox(height: 8),
                  _line('Affiliation', affiliation ?? 'N/A'),
                  const SizedBox(height: 8),
                  _line('Favorite Team', favoriteTeam ?? 'N/A'),
                  const SizedBox(height: 8),
                  _line('Lifetime Points', '$lifetime'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _line(String label, String value) {
    return Text(
      '$label: $value',
      style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade700),
      textAlign: TextAlign.center,
    );
  }
}
