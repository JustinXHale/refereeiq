import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:RefereeIQ/services/firestore_service.dart';
import 'package:RefereeIQ/services/connectivity_service.dart';
import 'package:RefereeIQ/screens/challenge_complete_screen.dart';

class ChallengeQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final int points; // 3 (easy), 5 (medium), 7 (hard)
  final String? videoUrl;
  int selectedIndex = -1;

  ChallengeQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.points,
    this.videoUrl,
  });

  factory ChallengeQuestion.fromMap(Map<String, dynamic> m) {
    return ChallengeQuestion(
      prompt: (m['prompt'] ?? '').toString(),
      options: ((m['options'] ?? []) as List).map((e) => e.toString()).toList(),
      correctIndex: (m['correctIndex'] ?? 0) as int,
      points: (m['points'] ?? 1) as int,
      videoUrl: (m['videoUrl'] ?? m['videoURL']) as String?,
    );
  }
}

class DailyChallengeTab extends StatefulWidget {
  const DailyChallengeTab({super.key});

  @override
  State<DailyChallengeTab> createState() => _DailyChallengeTabState();
}

class _DailyChallengeTabState extends State<DailyChallengeTab>
    with AutomaticKeepAliveClientMixin {
  // Loaded from Firestore
  List<ChallengeQuestion> _questions = [];

  // UI/state
  int _currentIndex = 0;
  bool _isSubmitted = false;
  bool _isFinished = false; // show “already completed” view inside the tab
  bool _isFinishing = false; // guard double-taps on Finish
  int _totalPoints = 0;

  // Loading state
  bool _loading = true;
  String? _loadError;

  int get _maxPoints => _questions.fold(0, (acc, q) => acc + q.points);

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _fetchToday();
  }

  Future<void> _fetchToday() async {
    try {
      final id = _todayDocId(); // YYYY-MM-DD-am/pm
      final snap = await FirebaseFirestore.instance
          .collection('daily_challenges')
          .doc(id)
          .get();

      if (!snap.exists) {
        // Even if there’s no doc yet, check if we already finished this block
        await _loadChallengeState();
        setState(() {
          _loading = false;
          _loadError = _isFinished ? null : 'empty';
        });
        return;
      }

      final data = snap.data()!;
      final arr = (data['questions'] as List<dynamic>);
      final qs = arr
          .map((e) =>
          ChallengeQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      setState(() {
        _questions = qs;
        _loading = false;
        _currentIndex = 0;
        _isSubmitted = false;
        _isFinished = false;
        _isFinishing = false;
        _totalPoints = 0;
      });

      // Restore local completion state (if user already finished this block)
      await _loadChallengeState();
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = 'Failed to load: $e';
      });
    }
  }

// === Local & remote completion state (per user, per block) ===
  Future<void> _loadChallengeState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final todayKey = _todayKey(); // e.g., 2025-08-10-am

    // 1) Cross‑device check: if an attempt exists in Firestore, we’re done.
    final attemptsRef = FirebaseFirestore.instance
        .collection('challenge_attempts')
        .doc('${user.uid}_$todayKey');

    final attemptSnap = await attemptsRef.get();
    if (attemptSnap.exists) {
      final data = attemptSnap.data()!;
      setState(() {
        _isFinished = true;                 // <- shows the finished/complete state
        _totalPoints = (data['score'] ?? 0) as int;
      });
      return;
    }

    // 2) Same‑device continuity: fall back to local prefs.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('challenge_done_${user.uid}_$todayKey') == true) {
      setState(() {
        _isFinished = true;                 // <- same finished/complete state
        _totalPoints =
            prefs.getInt('challenge_score_${user.uid}_$todayKey') ?? 0;
      });
    }
  }

  Future<void> _saveChallengeState() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final todayKey = _todayKey(); // includes -am / -pm

    if (user != null) {
      await prefs.setBool('challenge_done_${user.uid}_$todayKey', true);
      await prefs.setInt('challenge_score_${user.uid}_$todayKey', _totalPoints);
    }
  }

  // Keep local prefs in lockstep with Firestore doc id
  String _todayKey() => _todayDocId();

  String _todayDocId() {
    final chicago = tz.getLocation('America/Chicago');
    final now = tz.TZDateTime.now(chicago);
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final block = now.hour < 12 ? 'am' : 'pm';
    return '$y-$m-$d-$block'; // e.g., 2025-08-09-am
  }

  // === Quiz flow ===
  void _handleSubmit() {
    if (_isSubmitted) return; // safety
    setState(() {
      _isSubmitted = true;
      final q = _questions[_currentIndex];
      if (q.selectedIndex == q.correctIndex) {
        _totalPoints += q.points;
      }
    });
  }

  Future<void> _handleNextOrFinish() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isSubmitted = false;
      });
      return;
    }

    // Final question -> finish
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    try {
      await _saveChallengeState();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final todayKey = _todayDocId();
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
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Saved locally. Leaderboard may take a moment.')));
      }
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }

    if (!mounted) return;

    // Navigate to the completion screen; allow user to refresh when the next block drops
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeCompleteScreen(
          score: _totalPoints,
          maxScore: _maxPoints,
          nextDropLabel: _nextDropLabel(),
        ),
      ),
    );

    // If they tapped Refresh on that screen, reload today's challenge
    if (result == 'refresh' && mounted) {
      setState(() => _loading = true);
      await _fetchToday();
    }
  }

  // Single primary button handler
  void _onPrimaryButtonTap() {
    if (!_isSubmitted) {
      _handleSubmit();
    } else {
      _handleNextOrFinish();
    }
  }

  String _nextDropLabel() {
    // Schedule: 8:30 AM & 8:30 PM Central Time
    final chicago = tz.getLocation('America/Chicago');
    final nowCT = tz.TZDateTime.now(chicago);
    final todayAm = tz.TZDateTime(chicago, nowCT.year, nowCT.month, nowCT.day, 8, 30);
    final todayPm = tz.TZDateTime(chicago, nowCT.year, nowCT.month, nowCT.day, 20, 30);

    tz.TZDateTime nextCT;
    if (nowCT.isBefore(todayAm)) {
      nextCT = todayAm;
    } else if (nowCT.isBefore(todayPm)) {
      nextCT = todayPm;
    } else {
      nextCT = tz.TZDateTime(chicago, nowCT.year, nowCT.month, nowCT.day + 1, 8, 30);
    }

    // Display in device local time so users everywhere see the correct time
    final nextLocal = nextCT.toLocal();
    final hour = (nextLocal.hour % 12 == 0) ? 12 : nextLocal.hour % 12;
    final minute = nextLocal.minute.toString().padLeft(2, '0');
    final ampm = nextLocal.hour < 12 ? 'AM' : 'PM';

    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekday = weekdayNames[(nextLocal.weekday + 6) % 7];
    final month = monthNames[nextLocal.month - 1];

    return '$weekday, $month ${nextLocal.day} • $hour:$minute $ampm';
  }

  // --- Inline empty state (no challenge yet) ---
  Widget _buildChallengeEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/app_icon.png',
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) => Icon(
                Icons.flag_outlined,
                size: 64,
                color: colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Daily Challenge",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "New questions drop at 8:30 AM and 8:30 PM (CT).\n"
                  "Next drop: ${_nextDropLabel()}",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: () async {
                setState(() => _loading = true);
                await _fetchToday();
              },
              child: Text('Refresh',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Inline “already completed” view ---
  Widget _buildAlreadyCompleted(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 80, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('Challenge complete!',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('You scored $_totalPoints points this block.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 12),
            Text('Next drop: ${_nextDropLabel()}',
                style:
                GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                setState(() => _loading = true);
                await _fetchToday();
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text('Refresh',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    // If we know they finished this block, show the completion view first
    if (_isFinished) return _buildAlreadyCompleted(colorScheme);

    // Only show the empty state if not finished and no doc yet
    if (_loadError == 'empty') return _buildChallengeEmptyState(colorScheme);

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _loading = true);
                  _loadChallengeState();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 48, color: colorScheme.outlineVariant),
              const SizedBox(height: 12),
              const Text('No questions available for this block.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _loading = true);
                  _loadChallengeState();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final q = _questions[_currentIndex];

    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, _) {
        return SafeArea(
          bottom: true,
          child: Column(
            children: [
              if (!isOnline)
                MaterialBanner(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  content: const Text('Daily challenges require an internet connection'),
                  leading: Icon(Icons.wifi_off, color: colorScheme.onSurfaceVariant),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  actions: [
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              Expanded(
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
                  style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (q.videoUrl != null) ...[
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_off, size: 32, color: colorScheme.outlineVariant),
                          const SizedBox(height: 8),
                          Text('Clip coming soon', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ],
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
                    Text('Question Points: ${q.points}',
                        style: GoogleFonts.inter(fontSize: 14)),
                    Text('Total Points: $_totalPoints',
                        style: GoogleFonts.inter(fontSize: 14)),
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
                bg = colorScheme.primaryContainer;
              } else if (isSelected) {
                bg = colorScheme.errorContainer;
              } else {
                bg = colorScheme.surfaceContainerHighest;
              }
            } else {
              bg = isSelected
                  ? colorScheme.primary.withAlpha((0.3 * 255).toInt())
                  : colorScheme.surfaceContainerHighest;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: InkWell(
                onTap: _isSubmitted
                    ? null
                    : () => setState(() => q.selectedIndex = i),
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (_isSubmitted) ...[
                          if (i == q.correctIndex)
                            Icon(Icons.check_circle_outline, color: colorScheme.primary, size: 20)
                          else if (isSelected)
                            Icon(Icons.cancel_outlined, color: colorScheme.error, size: 20)
                          else
                            const SizedBox(width: 20),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: Text(q.options[i], style: GoogleFonts.inter(fontSize: 16))),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Single primary button (Submit -> Next/Finish)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                disabledForegroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32)),
              ),
              onPressed: (_isFinishing ||
                  (q.selectedIndex == -1 && !_isSubmitted))
                  ? null
                  : _onPrimaryButtonTap,
              child: _isFinishing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(
                !_isSubmitted
                    ? 'Submit'
                    : (_currentIndex == _questions.length - 1
                    ? 'Finish'
                    : 'Next'),
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
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
