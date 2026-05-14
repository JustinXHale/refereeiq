import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/admin_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late Future<AdminConfigSnapshot> _adminFuture;

  @override
  void initState() {
    super.initState();
    _adminFuture = AdminService().getConfig();
  }

  Future<Map<String, dynamic>?> _getUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Drawer(
        child: Center(child: Text('Not logged in')),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserProfile(user.uid),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name = data?['name'] ?? 'Guest';
        final affiliation = data?['affiliation'] ?? '';
        final photoURL = data?['photoURL'];

        return Drawer(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 56, bottom: 24, left: 16, right: 8),
                color: colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.close, color: colorScheme.onPrimary),
                        tooltip: 'Close menu',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: colorScheme.surfaceContainerHigh,
                          backgroundImage: (photoURL != null && photoURL.trim().isNotEmpty)
                              ? CachedNetworkImageProvider(photoURL)
                              : null,
                          child: (photoURL == null || photoURL.trim().isEmpty)
                              ? Icon(Icons.person, color: colorScheme.onPrimary)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.onPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (affiliation.isNotEmpty)
                                Text(
                                  affiliation,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              FutureBuilder<AdminConfigSnapshot>(
                future: _adminFuture,
                builder: (context, adminSnap) {
                  if (adminSnap.connectionState != ConnectionState.done) {
                    return const SizedBox.shrink();
                  }
                  final cfg = adminSnap.data;
                  if (cfg == null || !cfg.isAdmin) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    leading: Icon(Icons.admin_panel_settings, color: colorScheme.primary),
                    title: const Text('Admin'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/admin');
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Image.asset('assets/icons/app_icon.png', height: 32),
                    const SizedBox(height: 8),
                    Text(
                      'RefereeIQ',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
