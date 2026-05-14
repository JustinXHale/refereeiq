// lib/screens/leaderboard_tab.dart

import 'package:flutter/material.dart';
import 'package:RefereeIQ/screens/player_profile_screen.dart';
import 'package:RefereeIQ/services/firestore_service.dart';

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  final FirestoreService _firestoreService = FirestoreService();

  // Filters
  String selectedState = 'All';
  String selectedAffiliation = 'All';

  // Score type is stored internally in lowercase for Firestore queries.
  // Display mapping -> sentence case for the UI.
  final Map<String, String> _scoreLabels = const {
    'daily': 'Daily',
    'monthly': 'Monthly',
    'lifetime': 'Lifetime',
  };
  String selectedScoreType = 'daily'; // default to Daily

  // States list
  List<String> states = ['All'];
  bool isLoadingStates = true;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    final fetchedStates = await _firestoreService.getAvailableStates();
    if (!mounted) return;
    setState(() {
      states.addAll(fetchedStates);
      isLoadingStates = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return Column(
      children: [
        // Filters row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: isLoadingStates
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildDropdown<String>(
                      label: 'States',
                      value: selectedState,
                      items: states,
                      colorScheme: colorScheme,
                      onChanged: (value) =>
                          setState(() => selectedState = value!),
                    ),
                    _buildDropdown<String>(
                      label: 'Affiliation',
                      value: selectedAffiliation,
                      items: const ['All', 'Coach', 'Fan', 'Player', 'Referee'],
                      colorScheme: colorScheme,
                      onChanged: (value) =>
                          setState(() => selectedAffiliation = value!),
                    ),
                    // Sentence-case display; lowercase internal value
                    _buildDropdown<String>(
                      label: 'Score',
                      value: _scoreLabels[selectedScoreType]!,
                      items: _scoreLabels.values.toList(),
                      colorScheme: colorScheme,
                      onChanged: (display) {
                        final entry = _scoreLabels.entries
                            .firstWhere((e) => e.value == display);
                        setState(() => selectedScoreType = entry.key);
                      },
                    ),
                  ],
                ),
        ),

        // Table
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getLeaderboardFiltered(
              scoreType: selectedScoreType, // daily / monthly / lifetime
              state: selectedState == 'All' ? null : selectedState,
              affiliation:
              selectedAffiliation == 'All' ? null : selectedAffiliation,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final players = (snapshot.data ?? []).take(100).toList();

              if (players.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.leaderboard_outlined, size: 56, color: colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          'No results — try changing filters',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateColor.resolveWith(
                          (_) => colorScheme.primary,
                    ),
                    columnSpacing: 16,
                    columns: [
                      DataColumn(label: Text('#', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Name', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold))),
                      DataColumn(label: Tooltip(
                        message: 'Division',
                        child: Text('D', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                      )),
                      DataColumn(label: Tooltip(
                        message: 'Matches',
                        child: Text('M', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                      )),
                      DataColumn(label: Tooltip(
                        message: 'Level',
                        child: Text('L', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                      )),
                      DataColumn(label: Text('State', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold))),
                    ],
                    rows: List<DataRow>.generate(
                      players.length,
                          (index) {
                        final player = players[index];
                        final name = player['name'] ?? 'Unknown';
                        final state = player['state'] ?? '';
                        final type = player['type'] ?? '';

                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(
                              InkWell(
                                onTap: () =>
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlayerProfileScreen(player: player),
                                      ),
                                    ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, size: 18),
                                    const SizedBox(width: 4),
                                    Text(name),
                                    const SizedBox(width: 4),
                                    Icon(
                                      type == 'Referee'
                                          ? Icons.assignment
                                          : (type == 'Coach'
                                          ? Icons.group
                                          : Icons.sports),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(Text('${player['daily'] ?? 0}')),
                            DataCell(Text('${player['monthly'] ?? 0}')),
                            DataCell(Text('${player['lifetime'] ?? 0}')),
                            DataCell(Text(state)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Simple dropdown with a small label above it
  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4),
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              onChanged: onChanged,
              items: items
                  .map((T item) =>
                  DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
