import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChallengeCompleteScreen extends StatelessWidget {
  final int score;
  final int maxScore;
  final String nextDropLabel;

  const ChallengeCompleteScreen({
    super.key,
    required this.score,
    required this.maxScore,
    required this.nextDropLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Complete'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 80, color: cs.primary),
              const SizedBox(height: 24),
              Text('Great work!',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'You scored $score out of $maxScore.',
                style: GoogleFonts.inter(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Next challenge: $nextDropLabel',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 28),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                onPressed: () => Navigator.of(context).pop('refresh'),
                child: Text('Refresh', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
