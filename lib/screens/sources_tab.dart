// sources_tab.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'document_view_screen.dart';

class SourcesTab extends StatefulWidget {
  const SourcesTab({super.key});

  @override
  State<SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends State<SourcesTab> with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _docs = [
    {
      'title': 'World Rugby Laws 2024',
      'subtitle': 'Official Laws of Rugby Union for the 2024 season.',
      'category': 'World Rugby',
    },
    {
      'title': 'RefereeIQ Training Manual',
      'subtitle': 'Internal referee training resources and guidance.',
      'category': 'RefereeIQ',
    },
    {
      'title': 'MLR Competition Guidelines',
      'subtitle': 'Major League Rugby competition rules and procedures.',
      'category': 'MLR',
    },
    {
      'title': 'College Rugby Rulebook',
      'subtitle': 'Rules and adaptations for collegiate rugby competitions.',
      'category': 'World Rugby',
    },
    {
      'title': 'Texas Rugby Referee Union Docs',
      'subtitle': 'Resources and guidelines for Texas-based competitions.',
      'category': 'RefereeIQ',
    },
    {
      'title': 'Pōpolo Game Scenarios',
      'subtitle': 'Operational handbook for local rugby club competitions.',
      'category': 'RefereeIQ',
    },
  ];

  final List<String> _categories = [
    'All',
    'World Rugby',
    'RefereeIQ',
    'MLR',
  ];

  String _selectedCategory = 'All';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final colorScheme = Theme.of(context).colorScheme;
    final filteredDocs = _selectedCategory == 'All'
        ? _docs
        : _docs.where((doc) => doc['category'] == _selectedCategory).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                Tab(text: 'Sources'),
                Tab(text: 'Favorites'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Sources tab
                Column(
                  children: [
                    // Filter chips
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: Wrap(
                        spacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: colorScheme.primary,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? Colors.black : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Documents list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return Card(
                            color: const Color(0xFFFEF7E6),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                doc['title'],
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                doc['subtitle'],
                                style: GoogleFonts.inter(),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DocumentViewScreen(document: doc),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Favorites tab
                const Center(child: Text('Favorites will go here')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
