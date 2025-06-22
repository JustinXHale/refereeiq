// document_view_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentViewScreen extends StatelessWidget {
  final Map<String, dynamic> document;

  const DocumentViewScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          document['title'] ?? 'Document',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            document['title'] ?? 'Document Title',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            document['content'] ?? 'Document content goes here.',
            style: GoogleFonts.inter(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
