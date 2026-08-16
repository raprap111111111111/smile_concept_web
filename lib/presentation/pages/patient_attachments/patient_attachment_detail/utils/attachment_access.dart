import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/network/dio_client.dart';

/// Fetches token-based access URLs for patient attachments.
///
/// These URLs work in browser tabs, <img> tags, and print dialogs
/// WITHOUT requiring a Bearer token — the token is embedded in the URL.
///
/// Backend endpoint: GET /patient-attachments/{id}/access-url
/// Returns:
/// {
///   "file_url":     "https://.../patient-attachments/file/abc123xyz...",
///   "download_url": "https://.../patient-attachments/download/def456uvw...",
///   "expires_at":   "2026-08-16T16:35:00+00:00"
/// }
class AttachmentAccess {
  /// Returns a temporary URL for VIEWING the file inline.
  ///
  /// Use this for:
  /// - Opening the file in a new browser tab
  /// - Fetching bytes for print/preview
  /// - Embedding in <img> or <iframe>
  static Future<String> getFileUrl(WidgetRef ref, int attachmentId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      '/patient-attachments/$attachmentId/access-url',
    );

    final url = response.data?['data']?['file_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('No file URL returned by server');
    }
    return url;
  }

  /// Returns a temporary URL for DOWNLOADING the file with a friendly filename.
  ///
  /// Use this for:
  /// - "Download" button (browser saves with correct filename)
  /// - Force-download links
  static Future<String> getDownloadUrl(WidgetRef ref, int attachmentId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      '/patient-attachments/$attachmentId/access-url',
    );

    final url = response.data?['data']?['download_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('No download URL returned by server');
    }
    return url;
  }

  /// Convenience: returns BOTH URLs in a single API call.
  /// Useful when you need both for the same UI (e.g. detail page).
  static Future<AttachmentAccessUrls> getBoth(
    WidgetRef ref,
    int attachmentId,
  ) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      '/patient-attachments/$attachmentId/access-url',
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('No access data returned by server');
    }

    return AttachmentAccessUrls(
      fileUrl: data['file_url'] as String? ?? '',
      downloadUrl: data['download_url'] as String? ?? '',
      expiresAt: data['expires_at'] as String? ?? '',
    );
  }
}

/// Result object for both URLs + expiry.
class AttachmentAccessUrls {
  final String fileUrl;
  final String downloadUrl;
  final String expiresAt;

  const AttachmentAccessUrls({
    required this.fileUrl,
    required this.downloadUrl,
    required this.expiresAt,
  });
}