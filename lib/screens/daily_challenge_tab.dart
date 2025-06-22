// challenge_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab Bar
          TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Daily Challenge'),
              Tab(text: 'Leaderboard'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Daily Challenge tab
                const Center(child: Text('Daily Challenge will go here')),
                // Leaderboard tab
                const Center(child: Text('Leaderboard will go here')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
