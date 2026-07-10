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
  const DropdownError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: false,
      decoration: InputDecoration(
        labelText: 'Error',
        prefixIcon: const Icon(Icons.error_outline, color: Colors.red),
        errorText: message,
        border: const OutlineInputBorder(),
      ),
    );
  }
}