import 'package:flutter/material.dart';

// Example skeleton widget
class DropdownSkeleton extends StatelessWidget {
  final String label;
  const DropdownSkeleton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.hourglass_empty),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// Example error widget
class DropdownError extends StatelessWidget {
  final String message;

  /// Why the load failed — a 403, a dead API port, a parse error. Without it
  /// `message` alone ("Failed to load branches") names the symptom and hides
  /// every cause behind one string.
  final String? detail;

  final VoidCallback? onRetry;

  const DropdownError({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Error',
            prefixIcon: const Icon(Icons.error_outline, color: Colors.red),
            errorText: message,
            border: const OutlineInputBorder(),
          ),
        ),
        if (detail != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
            child: Text(
              detail!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        if (onRetry != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ),
      ],
    );
  }
}
