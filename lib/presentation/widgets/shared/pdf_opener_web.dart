import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation: create a Blob URL and open it in a new tab.
/// Chrome renders it with its built-in PDF viewer.
void openPdfBytes(Uint8List bytes, {required String filename}) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  anchor.click();

  // Revoke after a delay so the new tab has time to load.
  Future.delayed(const Duration(seconds: 30), () {
    html.Url.revokeObjectUrl(url);
  });
}