import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

class ChallengeQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final int points;
  final String? videoUrl;
  int selectedIndex = -1;

  ChallengeQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.points,
    this.videoUrl,
  });
}

class DailyChallengeTab extends StatefulWidget {
  const DailyChallengeTab({super.key});

  @override
  State<DailyChallengeTab> createState() => _DailyChallengeTabState();
}

class _DailyChallengeTabState extends State<DailyChallengeTab>
    with AutomaticKeepAliveClientMixin {
  final _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;

  final List<ChallengeQuestion> _questions = [
    ChallengeQuestion(
      prompt: 'What is the correct decision when a knock-on occurs?',
      options: ['Scrum', 'Penalty', 'Lineout', 'Free Kick'],
      correctIndex: 0,
      points: 5,
    ),
    ChallengeQuestion(
      prompt: 'What happens if a player is offside?',
      options: [
        'Penalty to the opposition',
        'Free kick to the player’s team',
        'Scrum to the player’s team',
        'No consequence'
      ],
      correctIndex: 0,
      points: 5,
    ),
    ChallengeQuestion(
      prompt: 'What is the minimum number of players in a lineout?',
      options: ['3', '2', '5', '7'],
      correctIndex: 1,
      points: 5,
    ),
  ];

  int _currentIndex = 0;
  bool _isSubmitted = false;
  bool _isFinished = false;
  int _totalPoints = 0;
  int get _maxPoints => _questions.fold(0, (sum, q) => sum + q.points);

  @override
  void initState() {
    super.initState();
    _loadChallengeState();
  }

  Future<void> _loadChallengeState() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestoreService.getPlayerProfile(user.uid);
      final data = doc.data();
      final lastCompleted = data?['lastChallengeDate'] as Timestamp?;
      if (lastCompleted != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (lastCompleted.toDate().isAfter(today)) {
          setState(() => _isFinished = true);
        }
      }
    }
  }

  Future<void> _saveChallengeState() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestoreService.saveScore(user.uid, _totalPoints);
      await _firestoreService.updatePlayerProfile(user.uid, {
        'lastChallengeDate': Timestamp.now(),
      });
    }
  }

  void _handleSubmit() {
    setState(() {
      _isSubmitted = true;
      final q = _questions[_currentIndex];
      if (q.selectedIndex == q.correctIndex) {
        _totalPoints += q.points;
      }
    });
  }

  void _handleNextOrFinish() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isSubmitted = false;
      });
    } else {
      setState(() => _isFinished = true);
      await _saveChallengeState();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_isFinished) {
      return _buildCongratulations(colorScheme);
    }

    final q = _questions[_currentIndex];
    final isLast = _currentIndex == _questions.length - 1;

    return SafeArea(
      bottom: true,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            q.prompt,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          ...List.generate(q.options.length, (index) {
            final isSelected = index == q.selectedIndex;
            final isCorrect = _isSubmitted && index == q.correctIndex;
            final isWrong = _isSubmitted && isSelected && index != q.correctIndex;

            Color? color;
            if (isCorrect) color = Colors.green;
            if (isWrong) color = Colors.red;
            if (isSelected && !_isSubmitted) color = colorScheme.primary;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: color?.withOpacity(0.2) ?? Colors.grey.shade200,
                title: Text(q.options[index], style: GoogleFonts.inter()),
                onTap: _isSubmitted
                    ? null
                    : () {
                  setState(() {
                    q.selectedIndex = index;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: q.selectedIndex == -1
                ? null
                : (_isSubmitted ? _handleNextOrFinish : _handleSubmit),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 48),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            child: Text(_isSubmitted ? (isLast ? 'Finish' : 'Next') : 'Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildCongratulations(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text('Congratulations!', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('You scored $_totalPoints out of $_maxPoints.', style: GoogleFonts.inter(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Check out today’s leaderboard via the Leaderboard tab.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
