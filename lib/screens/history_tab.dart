import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String? selectedLaw;
  bool _loading = true;
  String? _error;

  String _nextDropLabel() {
    // Your drops: 8:30 AM and 8:30 PM CT
    final now = DateTime.now();
    final am = DateTime(now.year, now.month, now.day, 8, 30);
    final pm = DateTime(now.year, now.month, now.day, 20, 30);

    DateTime next;
    if (now.isBefore(am)) {
      next = am;
    } else if (now.isBefore(pm)) {
      next = pm;
    } else {
      next = am.add(const Duration(days: 1));
    }

    final h = (next.hour % 12 == 0) ? 12 : next.hour % 12;
    final mm = next.minute.toString().padLeft(2, '0');
    final ap = next.hour < 12 ? 'AM' : 'PM';

    const w = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return '${w[(next.weekday + 6) % 7]}, ${m[next.month - 1]} ${next.day} • $h:$mm $ap CT';
  }

  Widget _buildHistoryEmptyState(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
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
              'No History...yet',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Answers unlock after the next challenge drops.\n'
                  'Next drop: ${_nextDropLabel()}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              onPressed: () async {
                setState(() => _loading = true);
                await _loadHistory(); // re-query Firestore
              },
              child: Text('Refresh', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_off, size: 56, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No results for "${selectedLaw ?? ''}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different law or clear the filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => selectedLaw = null),
              child: Text('Clear filter', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // Flattened list of past Q&A pulled from Firestore
  // Each item: {id, createdAt, block, prompt, options, correctIndex, points, lawReference}
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ===== Helpers for block / unlock logic =====

  // Current block based on device time (am before 12:00, pm after)
  String _currentBlock() {
    final now = DateTime.now();
    return now.hour < 12 ? 'am' : 'pm';
  }

  // Return true if a given docId (YYYY-MM-DD-am/pm) should be visible in history now
  bool _isUnlocked(String docId) {
    // Parse id
    // Expect "YYYY-MM-DD-am" or "YYYY-MM-DD-pm"
    final parts = docId.split('-');
    if (parts.length < 4) return true; // fallback: show if malformed
    final y = int.tryParse(parts[0]) ?? 1970;
    final m = int.tryParse(parts[1]) ?? 1;
    final d = int.tryParse(parts[2]) ?? 1;
    final block = parts[3].toLowerCase(); // "am"|"pm"

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(y, m, d);

    if (day.isBefore(today)) return true; // previous days always unlocked
    if (day.isAfter(today)) return false; // future (shouldn't happen)

    // Same day: unlock only if the current block is AFTER the doc's block
    final currentBlock = _currentBlock(); // "am" or "pm"
    if (block == 'am' && currentBlock == 'pm') return true; // morning is past once afternoon begins
    return false;
  }

  // ===== Load from Firestore =====
  Future<void> _loadHistory() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('daily_challenges')
          .orderBy('createdAt', descending: true)
          .limit(60) // grab a bunch; tweak if needed
          .get();

      final List<Map<String, dynamic>> out = [];

      for (final doc in qs.docs) {
        final id = doc.id; // YYYY-MM-DD-am/pm
        if (!_isUnlocked(id)) continue; // respect unlock rule

        final data = doc.data();
        final block = (data['block'] ?? '').toString();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        final questions = (data['questions'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>();

        for (final q in questions) {
          final prompt = (q['prompt'] ?? '').toString();
          final options = (q['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
          final correctIndex = (q['correctIndex'] is int) ? q['correctIndex'] as int : 0;
          final points = (q['points'] is int) ? q['points'] as int : 0;
          final lawRef = (q['lawReference']?.toString().trim().isEmpty ?? true)
              ? null
              : q['lawReference'].toString();

          out.add({
            'docId': id,
            'createdAt': createdAt,
            'block': block,
            'prompt': prompt,
            'options': options,
            'correctIndex': correctIndex,
            'answer': options.isNotEmpty && correctIndex >= 0 && correctIndex < options.length
                ? options[correctIndex]
                : '',
            'points': points,
            'lawReference': lawRef, // e.g., "Law 18 - Quick throw"
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _items = out;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load history: $e';
      });
    }
  }

  // Build law filter options from data (unique laws present)
  List<String?> _availableLaws() {
    final set = <String?>{null}; // null = All laws
    for (final it in _items) {
      final law = it['lawReference'] as String?;
      if (law != null && law.isNotEmpty) set.add(law);
    }
    final list = set.toList();
    // Keep "All laws" (null) first, rest sorted
    final rest = list.where((e) => e != null).cast<String>().toList()..sort();
    return [null, ...rest];
  }

  // Filter based on selected law
  List<Map<String, dynamic>> get _filtered {
    if (selectedLaw == null) return _items;
    return _items.where((m) => (m['lawReference'] ?? '') == selectedLaw).toList();
  }

  // ===== Law markdown extraction (your existing logic kept) =====
  Future<String> loadAndFilterMarkdown(String lawReference, String question) async {
    try {
      // Try to extract a law number from "Law 18 - ..." or "Law 18"
      final match = RegExp(r'Law\s+(\d{1,2})').firstMatch(lawReference);
      if (match == null) return 'No local law file found for "$lawReference".';
      final number = int.parse(match.group(1)!);

      final String content = await rootBundle.loadString(
        'assets/laws/rugbylaw${number.toString().padLeft(2, '0')}.md',
      );

      final lines = content.split('\n');
      final keywords = question.toLowerCase().split(RegExp(r'\W+')).where((k) => k.length > 3).toList();

      List<String> selectedSection = [];
      bool capturing = false;
      int currentHeaderLevel = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        if (trimmed.startsWith('#')) {
          capturing = false;
          final matchCount = keywords.where((word) => trimmed.toLowerCase().contains(word)).length;
          if (matchCount >= 2) {
            capturing = true;
            currentHeaderLevel = trimmed.indexOf(' ');
            selectedSection.add(trimmed);
          }
          continue;
        }

        if (capturing) {
          final isNewHeader = trimmed.startsWith('#');
          final newHeaderLevel = isNewHeader ? trimmed.indexOf(' ') : -1;
          if (isNewHeader && newHeaderLevel <= currentHeaderLevel) break;
          selectedSection.add(line);
        }
      }

      return selectedSection.isNotEmpty ? selectedSection.join('\n').trim() : content.trim();
    } catch (e) {
      return 'Error loading law file: $e';
    }
  }

  void _openChallengeDetail(Map<String, dynamic> item) async {
    final lawRef = (item['lawReference'] ?? '') as String;
    final question = (item['prompt'] ?? '') as String;

    String lawSection = 'No law reference provided.';
    if (lawRef.isNotEmpty) {
      lawSection = await loadAndFilterMarkdown(lawRef, question);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            children: [
              Text(
                question,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('Correct answer: ${item['answer']}', style: GoogleFonts.inter()),
              const SizedBox(height: 6),
              if (item['lawReference'] != null)
                Text(item['lawReference'], style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text('Relevant Law Section:', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              MarkdownBody(data: lawSection),
            ],
          ),
        ),
      ),
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final laws = _availableLaws();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/icons/app_icon.png', width: 28, height: 28),
                const SizedBox(width: 8),
                Text('Challenge History',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: selectedLaw,
              decoration: const InputDecoration(
                labelText: 'Filter by Law',
                border: OutlineInputBorder(),
              ),
              items: laws.map((law) {
                if (law == null) {
                  return const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Laws'),
                  );
                }
                return DropdownMenuItem<String?>(
                  value: law,
                  child: Text(law),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedLaw = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filtered.isEmpty
                  ? (selectedLaw != null && _items.isNotEmpty
                      ? _buildFilteredEmptyState(colorScheme)
                      : _buildHistoryEmptyState(colorScheme))
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final item = _filtered[index];
                  final createdAt = item['createdAt'] as DateTime?;
                  final when = createdAt != null
                      ? '${createdAt.month}/${createdAt.day} ${createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour < 12 ? 'AM' : 'PM'}'
                      : item['docId'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => _openChallengeDetail(item),
                      title: Text(item['prompt'] ?? '',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Answer: ${item['answer']}',
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (item['lawReference'] != null)
                                Text(item['lawReference'],
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              const Spacer(),
                              Text(when,
                                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
