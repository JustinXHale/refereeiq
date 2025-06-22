// sources_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Demo sources
    final sources = [
      {
        'title': 'World Rugby Laws',
        'subtitle': '2024 Official Laws',
        'icon': Icons.library_books,
      },
      {
        'title': 'USA Rugby Guidelines',
        'subtitle': 'Match Management Guide',
        'icon': Icons.article,
      },
      {
        'title': 'Pōpolo Game Scenarios',
        'subtitle': 'Approved Case Book',
        'icon': Icons.menu_book,
      },
      {
        'title': 'Training Modules',
        'subtitle': 'Referee Learning Center',
        'icon': Icons.school,
      },
    ];

    return Column(
      children: [
        // Title + description
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sources',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Curated references used by Sofia in responses.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),

        // Search field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search sources...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Source list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    source['icon'] as IconData,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    source['title'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    source['subtitle'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Open source details
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
