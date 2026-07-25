import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'hold_to_delete_button.dart';

class HoldToDeleteDialog extends StatefulWidget {
  final String title;
  final String itemName;
  final String? description;
  final Duration holdDuration;

  const HoldToDeleteDialog({
    super.key,
    required this.title,
    required this.itemName,
    this.description,
    this.holdDuration = const Duration(seconds: 2),
  });

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String itemName,
    String? description,
    Duration holdDuration = const Duration(seconds: 2),
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => HoldToDeleteDialog(
        title: title,
        itemName: itemName,
        description: description,
        holdDuration: holdDuration,
      ),
    );
    return result ?? false;
  }

  @override
  State<HoldToDeleteDialog> createState() => _HoldToDeleteDialogState();
}

class _HoldToDeleteDialogState extends State<HoldToDeleteDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.description ??
        "You are about to delete '${widget.itemName}'. This action cannot be undone.";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.title, style: AppTextStyles.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              HoldToDeleteButton(
                label: 'Hold to delete',
                hintText: 'Press and hold for \${widget.holdDuration.inSeconds} seconds',
                duration: widget.holdDuration,
                loading: _isDeleting,
                disabled: _isDeleting,
                onComplete: () {
                  if (!mounted) return;
                  setState(() => _isDeleting = true);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) Navigator.of(context).pop(true);
                  });
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isDeleting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
