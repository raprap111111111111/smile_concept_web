import 'package:flutter/material.dart';
import '/presentation/theme/app_colors.dart';

class AttachmentHelpers {
  static bool isImage(String fileType) {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp']
        .contains(fileType.toLowerCase());
  }

  static bool isPdf(String fileType) => fileType.toLowerCase() == 'pdf';

  static IconData categoryIcon(String category) {
    switch (category) {
      case 'xray':         return Icons.medical_information;
      case 'photo':        return Icons.camera_alt_outlined;
      case 'consent_form': return Icons.description_outlined;
      case 'lab_report':   return Icons.science_outlined;
      case 'prescription': return Icons.medication_outlined;
      default:             return Icons.insert_drive_file_outlined;
    }
  }

  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':     return AppColors.statusPending;
      case 'moderate': return AppColors.statusNoShow;
      case 'severe':
      case 'heavy':    return AppColors.error;
      default:         return AppColors.info;
    }
  }

  static String formatConditionName(String condition) {
    return condition
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final min  = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:$min $amPm';
  }
}