import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String? selectedLaw;

  final List<Map<String, String>> pastChallenges = [
    {
      'question': 'What is required for a quick throw-in?',
      'answer': 'The same ball, thrown in straight, from the correct spot.',
      'law': 'Law 18',
    },
    {
      'question': 'How far back must the defending team retreat?',
      'answer': '10 meters from the mark of the penalty or free-kick.',
      'law': 'Law 10',
    },
    {
      'question': 'When is a scrum awarded?',
      'answer': 'For minor infringements or accidental knock-ons.',
      'law': 'Law 19',
    },
    {
      'question': 'Can a try be scored from a maul?',
      'answer': 'Yes, if the ball is grounded legally after forward progress.',
      'law': 'Law 16',
    },
  ];

  List<Map<String, String>> get filteredChallenges {
    if (selectedLaw == null) return pastChallenges;
    return pastChallenges.where((q) => q['law'] == selectedLaw).toList();
  }

  Future<String> loadAndFilterMarkdown(String lawNumber, String question) async {
    try {
      final int number = int.parse(lawNumber.split(' ').last);
      final String content = await rootBundle.loadString('assets/laws/rugbylaw${number.toString().padLeft(2, '0')}.md');

      final lines = content.split('\n');
      final keywords = question.toLowerCase().split(RegExp(r'\W+')).where((k) => k.length > 3).toList();

      List<String> selectedSection = [];
      bool capturing = false;
      int currentHeaderLevel = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        // Check for markdown header
        if (trimmed.startsWith('#')) {
          capturing = false;

          // Count how many keywords match the header line
          final matchCount = keywords.where((word) => trimmed.toLowerCase().contains(word)).length;

          // Require 2+ keyword matches to trigger
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

          // Stop if next header is same or higher level
          if (isNewHeader && newHeaderLevel <= currentHeaderLevel) break;

          selectedSection.add(line);
        }
      }

      return selectedSection.isNotEmpty
          ? selectedSection.join('\n').trim()
          : content.trim(); // fallback to full law
    } catch (e) {
      return 'Error loading law file: $e';
    }
  }

  void _openChallengeDetail(Map<String, String> item) async {
    final law = item['law']!;
    final question = item['question']!;
    final relevantSection = await loadAndFilterMarkdown(law, question);

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
                item['question']!,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text("Answer: ${item['answer']!}"),
              const SizedBox(height: 12),
              Text(item['law']!),
              const SizedBox(height: 20),
              Text('Relevant Law Section:', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              MarkdownBody(data: relevantSection),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/app_icon.png',
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Challenge History',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedLaw,
              decoration: const InputDecoration(
                labelText: 'Filter by Law',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Laws')),
                ...List.generate(21, (index) {
                  final law = 'Law ${index + 1}';
                  return DropdownMenuItem(value: law, child: Text(law));
                }),
              ],
              onChanged: (value) => setState(() => selectedLaw = value),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: filteredChallenges.isEmpty
                  ? const Center(child: Text('No questions match the selected filters.'))
                  : ListView.builder(
                itemCount: filteredChallenges.length,
                itemBuilder: (context, index) {
                  final item = filteredChallenges[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => _openChallengeDetail(item),
                      title: Text(
                        item['question']!,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Answer: ${item['answer']!}',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['law']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
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