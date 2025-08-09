import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:RefereeIQ/services/firestore_service.dart';

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
  const DailyChallengeTab({Key? key}) : super(key: key);

  @override
  State<DailyChallengeTab> createState() => _DailyChallengeTabState();
}

class _DailyChallengeTabState extends State<DailyChallengeTab>
    with AutomaticKeepAliveClientMixin {
  final List<ChallengeQuestion> _questions = [
    ChallengeQuestion(
      prompt: 'What is the maximum points for a penalty goal?',
      options: ['1', '2', '3', '4'],
      correctIndex: 2,
      points: 3,
    ),
    ChallengeQuestion(
      prompt: 'Watch this scrum technique and identify the incorrect bind.',
      options: [
        'A: Shoulder bind',
        'B: Arm bind',
        'C: Wrist bind',
        'D: Hand bind'
      ],
      correctIndex: 1,
      points: 5,
      videoUrl: 'https://example.com/scrum.mp4',
    ),
    ChallengeQuestion(
      prompt: 'Which law allows a quick throw-in?',
      options: ['Law 15', 'Law 16', 'Law 17', 'Law 18'],
      correctIndex: 2,
      points: 3,
    ),
    ChallengeQuestion(
      prompt: 'In a ruck, can a player use their feet to win the ball?',
      options: [
        'Yes',
        'Only behind the ball',
        'No',
        'Only in bound area'
      ],
      correctIndex: 2,
      points: 5,
    ),
    ChallengeQuestion(
      prompt: 'Which score gives 5 points?',
      options: ['Drop goal', 'Try', 'Penalty', 'Conversion'],
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
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final todayKey = _todayKey();

    if (user != null && prefs.getBool('challenge_done_${user.uid}_$todayKey') == true) {
      setState(() {
        _isFinished = true;
        _totalPoints = prefs.getInt('challenge_score_${user.uid}_$todayKey') ?? 0;
      });
    }
  }

  Future<void> _saveChallengeState() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final todayKey = _todayKey();

    if (user != null) {
      await prefs.setBool('challenge_done_${user.uid}_$todayKey', true);
      await prefs.setInt('challenge_score_${user.uid}_$todayKey', _totalPoints);
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}${now.month}${now.day}';
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
      setState(() {
        _isFinished = true;
      });

      await _saveChallengeState();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final todayKey = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
        final attemptsRef = FirebaseFirestore.instance
            .collection('challenge_attempts')
            .doc('${user.uid}_$todayKey');

        final attemptSnapshot = await attemptsRef.get();

        if (!attemptSnapshot.exists) {
          final profileSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final profileData = profileSnapshot.data();

          if (profileData != null) {
            await FirestoreService().submitScore(
              uid: user.uid,
              name: profileData['name'] ?? 'Guest',
              state: profileData['state'] ?? 'Unknown',
              type: profileData['affiliation'] ?? 'Unknown',
              score: _totalPoints,
            );

            await attemptsRef.set({
              'uid': user.uid,
              'date': Timestamp.now(),
              'score': _totalPoints,
            });
          }
        } else {
          debugPrint("User has already submitted a challenge today.");
        }
      }
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
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                if (q.videoUrl != null) ...[
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  q.prompt,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question Points: ${q.points}', style: GoogleFonts.inter(fontSize: 14)),
                    Text('Total Points: $_totalPoints', style: GoogleFonts.inter(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          ...List.generate(q.options.length, (i) {
            final isSelected = q.selectedIndex == i;
            Color bg;
            if (_isSubmitted) {
              if (i == q.correctIndex) {
                bg = Colors.green.shade200;
              } else if (isSelected) {
                bg = Colors.red.shade200;
              } else {
                bg = Colors.grey.shade200;
              }
            } else {
              bg = isSelected ? colorScheme.primary.withAlpha((0.3 * 255).toInt()) : Colors.grey.shade200;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: GestureDetector(
                onTap: _isSubmitted ? null : () => setState(() => q.selectedIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(q.options[i], style: GoogleFonts.inter(fontSize: 16)),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    onPressed: (q.selectedIndex == -1 || _isSubmitted) ? null : _handleSubmit,
                    child: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    onPressed: _isSubmitted ? _handleNextOrFinish : null,
                    child: Text(
                      _isSubmitted ? (isLast ? 'Finish' : 'Next') : 'Next',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
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
            Text('Rank today: #1', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            Text('Check out today’s leaderboard via the Leaderboard tab.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
