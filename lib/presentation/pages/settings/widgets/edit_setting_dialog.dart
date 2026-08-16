// lib/presentation/pages/settings/widgets/edit_setting_dialog.dart

import 'package:flutter/material.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class EditSettingDialog extends StatefulWidget {
  final Map<String, dynamic> setting;
  final Future<void> Function(String key, String value) onSave;

  const EditSettingDialog({
    super.key,
    required this.setting,
    required this.onSave,
  });

  @override
  State<EditSettingDialog> createState() => _EditSettingDialogState();
}

class _EditSettingDialogState extends State<EditSettingDialog> {
  late final TextEditingController _controller;
  late bool _boolValue;
  bool _isSaving = false;

  String get _type => widget.setting['type']?.toString() ?? 'string';
  String get _key => widget.setting['key']?.toString() ?? '';
  String get _label => widget.setting['label']?.toString() ?? _key;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.setting['value']?.toString() ?? '',
    );
    _boolValue = _asBool(widget.setting['value']);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final value = _type == 'boolean'
          ? (_boolValue ? '1' : '0')
          : _controller.text.trim();
      await widget.onSave(_key, value);
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Setting updated successfully', AppColors.success);
    } catch (error) {
      if (!mounted) return;
      _showSnack(describeError(error), AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft:
                      Radius.circular(AppDimensions.borderRadiusLarge),
                  topRight:
                      Radius.circular(AppDimensions.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: AppDimensions.iconSize,
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Edit setting value',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadius,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: AppDimensions.iconSize,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: _type == 'boolean'
                  ? _BooleanToggle(
                      value: _boolValue,
                      onChanged: (v) => setState(() => _boolValue = v),
                    )
                  : TextFormField(
                      controller: _controller,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      keyboardType: (_type == 'integer' || _type == 'float')
                          ? const TextInputType.numberWithOptions(
                              decimal: true,
                            )
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Value',
                        hintText: 'Enter value...',
                        prefixIcon: Icon(
                          _iconForType(_type),
                          size: AppDimensions.iconSizeMedium,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),

            // ── Footer ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLarge,
                        vertical: AppDimensions.paddingSmall,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: AppColors.primaryLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLarge,
                        vertical: AppDimensions.paddingSmall,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadius,
                        ),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'boolean':
        return Icons.toggle_on_rounded;
      case 'integer':
      case 'float':
        return Icons.pin_rounded;
      case 'json':
        return Icons.data_object_rounded;
      case 'date':
        return Icons.calendar_today_rounded;
      default:
        return Icons.tune_rounded;
    }
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return fallback;
  }
}

// ─── Boolean Toggle ───────────────────────────────────────────
class _BooleanToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BooleanToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = value ? AppColors.success : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
            child: Icon(
              value ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: AppDimensions.iconSizeSmall,
              color: color,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value ? 'Enabled' : 'Disabled',
                  style: AppTextStyles.labelMedium.copyWith(color: color),
                ),
                Text(
                  value
                      ? 'This setting is currently active'
                      : 'This setting is currently inactive',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.success,
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor:
                AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}