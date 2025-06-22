// challenge_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'daily_challenge_tab.dart';
import 'leaderboard_tab.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: colorScheme.primary,
            child: Container(
              color: colorScheme.primary,
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(0),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black,
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 14,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Daily Challenge'),
                  Tab(text: 'Leaderboard'),
                ],
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                DailyChallengeTab(),
                LeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}