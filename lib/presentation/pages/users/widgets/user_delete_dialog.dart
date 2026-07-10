import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class UserDeleteDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDeleteDialog({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString() ?? 'this user';

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text(
        'Delete User',
        style: TextStyle(color: Colors.white),
      ),
      content: Text(
        "Are you sure you want to delete '$name'?",
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
