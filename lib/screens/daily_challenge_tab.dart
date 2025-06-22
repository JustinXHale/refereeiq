// daily_challenge_tab.dart (placeholder version)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyChallengeTab extends StatelessWidget {
  const DailyChallengeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Daily Challenge',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Coming soon...',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}