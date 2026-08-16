import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '/core/config/api_config.dart';
import '/core/network/dio_client.dart';
import '/presentation/theme/app_colors.dart';

/// Opens or downloads a file with proper authentication.
class FileOpener {
  /// Downloads the file via Dio (with auth), then opens it in a new tab / share sheet.
  static Future<void> openAuthenticated(
    BuildContext context,
    WidgetRef ref, {
    required int attachmentId,
    required String fileName,
    String? mimeType,
  }) async {
    _showLoading(context);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<List<int>>(
        ApiConfig.attachmentFileUrl(attachmentId),
        options: Options(responseType: ResponseType.bytes),
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final bytes = Uint8List.fromList(response.data!);

      // ✅ Use printing package's sharePdf as a universal "open" mechanism
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _showError(context, 'Failed to open file: $e');
      }
    }
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 16),
                Text('Opening file…'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}