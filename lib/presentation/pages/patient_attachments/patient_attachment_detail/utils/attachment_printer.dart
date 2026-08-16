import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '/core/network/dio_client.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/theme/app_colors.dart';
import 'attachment_access.dart';       // ✅ NEW — use shared helper
import '/presentation/pages/patient_attachments/utils/attachment_helpers.dart';

/// Handles printing patient attachments (PDFs and images).
class AttachmentPrinter {
  static Future<void> print(
    BuildContext context,
    WidgetRef ref,
    PatientAttachment attachment,
  ) async {
    final canPrint = AttachmentHelpers.isPdf(attachment.fileType) ||
        AttachmentHelpers.isImage(attachment.fileType);

    if (!canPrint) {
      _showError(context, 'This file type cannot be printed.');
      return;
    }

    _showLoading(context);

    try {
      // ✅ Step 1: Get a temporary access URL (via shared helper)
      final accessUrl = await AttachmentAccess.getFileUrl(ref, attachment.id);

      // ✅ Step 2: Fetch the file bytes using plain Dio (no auth interceptor)
      final bytes = await _fetchBytes(accessUrl);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (AttachmentHelpers.isPdf(attachment.fileType)) {
        await _printPdf(bytes, attachment.fileName);
      } else {
        await _printImage(bytes, attachment.fileName);
      }

      // ✅ Log print action (silent fail)
      _logPrint(ref, attachment.id);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _showError(context, 'Failed to print: ${_friendlyError(e)}');
      }
    }
  }

  // ══════════════════════════════════════════════════════════

  /// Download the raw file bytes (plain Dio, no auth needed).
  static Future<Uint8List> _fetchBytes(String url) async {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data == null || response.data!.isEmpty) {
      throw Exception('Empty file received');
    }

    return Uint8List.fromList(response.data!);
  }

  static Future<void> _printPdf(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(
      name: fileName,
      onLayout: (_) async => bytes,
    );
  }

  static Future<void> _printImage(Uint8List bytes, String fileName) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(bytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              fileName,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
            pw.Expanded(
              child: pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (_) async => pdf.save(),
    );
  }

  /// Log print action to backend for audit trail (silent fail).
  static Future<void> _logPrint(WidgetRef ref, int attachmentId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/patient-attachments/$attachmentId/print-log');
    } catch (_) {
      // Silent — print already succeeded
    }
  }

  // ══════════════════════════════════════════════════════════
  // UI Helpers
  // ══════════════════════════════════════════════════════════

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Preparing to print…'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static String _friendlyError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 401) return 'Not authorized';
      if (status == 403) return 'Access token expired';
      if (status == 404) return 'File not found';
      return 'Network error';
    }
    return e.toString();
  }
}