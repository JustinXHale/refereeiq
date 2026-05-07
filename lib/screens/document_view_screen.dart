// document_view_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_view_screen.dart';

class DocumentViewScreen extends StatefulWidget {
  final Map<String, dynamic> document;

  const DocumentViewScreen({super.key, required this.document});

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  bool _openedPdf = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAssetPdf(BuildContext context, String assetPath, String title) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final filename = assetPath.split('/').last;
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewScreen(
          filePath: file.path,
          title: title.isEmpty ? filename : title,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_openedPdf) return;
    final assetPath = widget.document['assetPath'] as String?;
    final isPdf = assetPath != null && assetPath.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      _openedPdf = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openAssetPdf(
          context,
          assetPath,
          (widget.document['title'] ?? '').toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = widget.document['url'] as String?;
    final content = _formatContent((widget.document['content'] ?? '').toString());
    final assetPath = widget.document['assetPath'] as String?;
    final isPdf = assetPath != null && assetPath.toLowerCase().endsWith('.pdf');
    final docTitle = (widget.document['title'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document['title'] ?? 'Document',
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
            widget.document['title'] ?? 'Document Title',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (!isPdf)
            MarkdownBody(
              data: content,
              onTapLink: (label, href, title) {
                if (href != null) _openUrl(href);
              },
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                h1: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                h2: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                h3: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                blockquote: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  fontStyle: FontStyle.italic,
                ),
                blockquotePadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: const Color(0xFFFEF7E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                listBullet: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                strong: GoogleFonts.inter(fontWeight: FontWeight.w700),
                a: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          if (isPdf) ...[
            Text(
              'This source is a PDF.',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openAssetPdf(context, assetPath, docTitle),
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(
                'Open PDF',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
          if (url != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openUrl(url),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                'View Full Document',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatContent(String content) {
  if (content.isEmpty) return content;
  var text = content;
  // Drop top-level header to avoid duplicate title with app bar.
  if (text.startsWith('# ')) {
    final firstNewline = text.indexOf('\n');
    if (firstNewline != -1) {
      text = text.substring(firstNewline + 1).trimLeft();
    }
  }
  // Bold subsection numbers like "3.1", "3.2.1" at line starts.
  text = text.replaceAllMapped(
    RegExp(r'^(\d+(?:\.\d+)+)\s+', multiLine: true),
    (m) => '**${m.group(1)}** ',
  );
  return text;
}
