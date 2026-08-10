import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/consent_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'pdf_opener_web.dart' if (dart.library.io) 'pdf_opener_stub.dart';

/// Web-first PDF viewer that hands the PDF bytes to Chrome's native viewer
/// via a Blob URL. This bypasses Flutter's canvas rendering entirely — no
/// SfPdfViewer, no pdfx, no black screens.
///
/// On mobile/desktop this falls back to a "Download to open" flow.
class PdfViewerPage extends ConsumerStatefulWidget {
  final String title;
  final int consentId;

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.consentId,
  });

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends ConsumerState<PdfViewerPage> {
  Uint8List? _bytes;
  String? _error;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _loadAndOpen();
  }

  Future<void> _loadAndOpen() async {
    try {
      final bytes = await ref
          .read(consentRepositoryProvider)
          .getConsentPdfBytes(widget.consentId);

      if (!mounted) return;

      setState(() => _bytes = bytes);

      if (kIsWeb) {
        // Hand the bytes to Chrome's native PDF viewer.
        openPdfBytes(bytes, filename: 'consent-${widget.consentId}.pdf');
        if (mounted) setState(() => _opened = true);
      }
    } catch (e, st) {
      debugPrint('PDF error: $e\n$st');
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load PDF',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _bytes = null;
                    _opened = false;
                  });
                  _loadAndOpen();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // On web the bytes were handed to a new tab; show a status page.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf,
                size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              _opened
                  ? 'PDF opened in a new tab'
                  : 'PDF ready (${(_bytes!.length / 1024).toStringAsFixed(1)} KB)',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _opened
                  ? 'If the tab did not open, allow pop-ups and try again.'
                  : 'Tap the button below to open it.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                openPdfBytes(_bytes!,
                    filename: 'consent-${widget.consentId}.pdf');
                setState(() => _opened = true);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF'),
            ),
          ],
        ),
      ),
    );
  }
}