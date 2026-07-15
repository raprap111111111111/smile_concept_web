// lib/presentation/pages/treatment_plans/widgets/dropdown_states.dart

import 'package:flutter/material.dart';

class DropdownLoading extends StatelessWidget {
  final String label;
  const DropdownLoading({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading...'),
        ],
      ),
    );
  }
}

class DropdownError extends StatelessWidget {
  final String label;
  final String error;
  final VoidCallback onRetry;

  const DropdownError({
    super.key,
    required this.label,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: 'Failed to load',
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}