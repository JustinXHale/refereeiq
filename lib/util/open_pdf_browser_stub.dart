import 'dart:typed_data';

/// No-op on non-web; [openPdfBytesInBrowser] is only called when `kIsWeb` is true.
void openPdfBytesInBrowser(Uint8List bytes, String filename) {}
