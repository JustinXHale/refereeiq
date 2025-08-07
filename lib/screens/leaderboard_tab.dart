// leaderboard_tab.dart (fixed overflow + tightened columns)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:RefereeIQ/screens/player_profile_screen.dart';

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  final FirestoreService _firestoreService = FirestoreService();
  String selectedState = 'All';
  String selectedAffiliation = 'All';
  String selectedScoreType = 'lifetime';

  List<String> states = ['All'];
  bool isLoadingStates = true;

  @override
  void initState() {
    super.initState();
    _firestoreService.getAvailableStates().then((fetchedStates) {
      setState(() {
        states.addAll(fetchedStates);
        isLoadingStates = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoadingStates)
                const CircularProgressIndicator()
              else ...[
                _buildDropdown<String>(
                  label: 'State',
                  value: selectedState,
                  items: states,
                  onChanged: (value) => setState(() => selectedState = value!),
                ),
                const SizedBox(width: 12),
                _buildDropdown<String>(
                  label: 'Affil',
                  value: selectedAffiliation,
                  items: ['All', 'Referee', 'Coach', 'Player'],
                  onChanged: (value) => setState(() => selectedAffiliation = value!),
                ),
                const SizedBox(width: 12),
                _buildDropdown<String>(
                  label: 'Score',
                  value: selectedScoreType,
                  items: ['lifetime', 'monthly', 'daily'],
                  onChanged: (value) => setState(() => selectedScoreType = value!),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getLeaderboardFiltered(
              scoreType: selectedScoreType,
              state: selectedState == 'All' ? null : selectedState,
              affiliation: selectedAffiliation == 'All' ? null : selectedAffiliation,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \${snapshot.error}'));
              }

              final players = snapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                          (states) => colorScheme.primary,
                    ),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('#', style: TextStyle(color: Colors.black))),
                      DataColumn(label: Text('Name', style: TextStyle(color: Colors.black))),
                      DataColumn(label: Text('D', style: TextStyle(color: Colors.black))),
                      DataColumn(label: Text('M', style: TextStyle(color: Colors.black))),
                      DataColumn(label: Text('L', style: TextStyle(color: Colors.black))),
                      DataColumn(label: Text('State', style: TextStyle(color: Colors.black))),
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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlayerProfileScreen(player: player),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person),
                                    const SizedBox(width: 4),
                                    Text(name),
                                    const SizedBox(width: 4),
                                    Icon(
                                      type == 'Referee'
                                          ? Icons.assignment
                                          : type == 'Coach'
                                          ? Icons.group
                                          : Icons.sports,
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

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButton<T>(
      value: value,
      hint: Text(label),
      onChanged: onChanged,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
    );
  }
}
