import 'dart:typed_data';

/// Non-web fallback. On mobile/desktop use the `printing` package instead.
void openPdfBytes(Uint8List bytes, {required String filename}) {
  throw UnsupportedError(
    'openPdfBytes is only implemented for Flutter Web. '
    'On mobile use Printing.sharePdf() or path_provider + open_file.',
  );
}

void downloadPdfBytes(Uint8List bytes, {required String filename}) {
  throw UnsupportedError(
    'downloadPdfBytes is only implemented for Flutter Web.',
  );
}