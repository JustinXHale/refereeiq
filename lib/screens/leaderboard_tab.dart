// leaderboard_tab.dart (fixed overflow + tightened columns)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'player_profile_screen.dart';

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> players = [
      {
        'name': 'Alex M.',
        'affiliation': 'USA Rugby',
        'team': 'Austin Blacks',
        'daily': 15,
        'monthly': 120,
        'lifetime': 520,
        'region': 'USA',
        'image': 'https://via.placeholder.com/100'
      },
      {
        'name': 'Taylor R.',
        'affiliation': 'RFU',
        'team': 'London Irish',
        'daily': 12,
        'monthly': 90,
        'lifetime': 450,
        'region': 'UK',
        'image': 'https://via.placeholder.com/100'
      },
      {
        'name': 'Jordan C.',
        'affiliation': 'ARU',
        'team': 'Sydney University',
        'daily': 10,
        'monthly': 80,
        'lifetime': 400,
        'region': 'AUS',
        'image': 'https://via.placeholder.com/100'
      },
      {
        'name': 'Sam K.',
        'affiliation': 'NZ Rugby',
        'team': 'Canterbury',
        'daily': 8,
        'monthly': 70,
        'lifetime': 300,
        'region': 'NZ',
        'image': 'https://via.placeholder.com/100'
      },
      {
        'name': 'Jamie B.',
        'affiliation': 'SARU',
        'team': 'Cape Town Stormers',
        'daily': 5,
        'monthly': 60,
        'lifetime': 250,
        'region': 'SA',
        'image': 'https://via.placeholder.com/100'
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            'Leaderboard',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('D')),
                DataColumn(label: Text('M')),
                DataColumn(label: Text('L')),
                DataColumn(label: Text('R')),
              ],
              rows: List<DataRow>.generate(
                players.length,
                    (index) {
                  final player = players[index];
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerProfileScreen(player: player),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(player['image']),
                                radius: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                player['name'],
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text('${player['daily']}')),
                      DataCell(Text('${player['monthly']}')),
                      DataCell(Text('${player['lifetime']}')),
                      DataCell(Text(player['region'])),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}