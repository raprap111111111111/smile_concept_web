// lib/presentation/widgets/shared/pdf_opener_web.dart

import 'dart:typed_data';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Opens PDF in a new browser tab using Chrome's built-in PDF viewer.
///
/// Do NOT set the `download` attribute — that forces the browser to save
/// the file instead of rendering it in the tab.
void openPdfBytes(Uint8List bytes, {required String filename}) {
  // ── Convert Uint8List → JS-compatible Blob ────────────────────────────
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );

  // ── Create a temporary object URL ─────────────────────────────────────
  final url = web.URL.createObjectURL(blob);

  // ── Open in a new tab (browser will render the PDF inline) ───────────
  final win = web.window.open(url, '_blank');

  // ── Fallback: if popup was blocked, use anchor click ─────────────────
  if (win == null) {
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..target = '_blank'
      ..rel = 'noopener noreferrer';
    // ⚠️ Deliberately NO `.download = filename` — that forces save
    anchor.click();
  }

  // ── Revoke after 60s so the viewer has time to fully load ────────────
  Future.delayed(const Duration(seconds: 60), () {
    web.URL.revokeObjectURL(url);
  });
}

/// Force-download the PDF (for a separate "Download" button).
/// This DOES use the `download` attribute to trigger a file save.
void downloadPdfBytes(Uint8List bytes, {required String filename}) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..target = '_blank'
    ..rel = 'noopener noreferrer'
    ..download = filename;   // ✅ forces save dialog

  anchor.click();

  Future.delayed(const Duration(seconds: 10), () {
    web.URL.revokeObjectURL(url);
  });
}