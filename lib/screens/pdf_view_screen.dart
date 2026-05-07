import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfViewScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfViewScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  bool _isReady = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text(
          widget.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            onRender: (_) {
              if (mounted) {
                setState(() {
                  _isReady = true;
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _error = error.toString();
                });
              }
            },
          ),
          if (!_isReady && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: Text(
                'Could not load PDF.',
                style: GoogleFonts.inter(),
              ),
            ),
        ],
      ),
    );
  }
}
