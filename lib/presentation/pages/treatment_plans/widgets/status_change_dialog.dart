// lib/presentation/pages/treatment_plans/widgets/status_change_dialog.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class StatusChangeDialog extends StatefulWidget {
  final String currentStatus;

  const StatusChangeDialog({super.key, required this.currentStatus});

  @override
  State<StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<StatusChangeDialog> {
  static const _statuses = [
    'draft',
    'proposed',
    'accepted',
    'completed',
    'rejected',
  ];

  late String _selected;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.currentStatus;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _requiresReason =>
      _selected == 'rejected' || _selected == 'completed';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        side: const BorderSide(color: AppColors.line),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentWithOpacity(0.22),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(
              Icons.sync,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Change Status',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.ink),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New Status',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((s) {
                final isSelected = s == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadius),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.line,
                      ),
                    ),
                    child: Text(
                      _capitalize(s),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_requiresReason) ...[
              const SizedBox(height: 18),
              Text(
                'Reason ${_selected == 'rejected' ? '*' : '(optional)'}',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter reason...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
              side: const BorderSide(color: AppColors.line),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        FilledButton(
          onPressed: () {
            if (_selected == 'rejected' &&
                _reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Reason is required to reject'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'status': _selected,
              if (_reasonController.text.trim().isNotEmpty)
                'reason': _reasonController.text.trim(),
            });
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
            ),
          ),
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}