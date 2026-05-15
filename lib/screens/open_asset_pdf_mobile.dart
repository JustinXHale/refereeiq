import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:RefereeIQ/screens/pdf_view_screen.dart';

Future<void> pushPdfViewFromAssetBytes(
  BuildContext context,
  Uint8List bytes,
  String filename,
  String title,
) async {
  final file = File('${Directory.systemTemp.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  if (!context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (context) => PdfViewScreen(
        filePath: file.path,
        title: title,
      ),
    ),
  );
}
