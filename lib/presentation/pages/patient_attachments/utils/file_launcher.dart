import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

class FileLauncher {
  static Future<void> openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched && context.mounted) {
        _showError(context, 'Could not open file');
      }
    } catch (e) {
      if (context.mounted) _showError(context, describeError(e));
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}