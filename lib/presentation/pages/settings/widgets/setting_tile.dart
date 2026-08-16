// lib/presentation/pages/settings/widgets/setting_tile.dart

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class SettingTile extends StatelessWidget {
  final Map<String, dynamic> setting;
  final bool showDivider;
  final VoidCallback onTap;

  const SettingTile({
    super.key,
    required this.setting,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = setting['label']?.toString() ??
        setting['key']?.toString() ??
        'Setting';
    final description = setting['description']?.toString() ?? '';
    final value = setting['value']?.toString() ?? '';
    final type = setting['type']?.toString() ?? 'string';
    final isEditable = _asBool(setting['is_editable'], fallback: true);
    final displayValue = _displayValue(value, type);

    return Column(
      children: [
        InkWell(
          onTap: isEditable ? onTap : null,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.cardPaddingMedium,
              vertical: AppDimensions.paddingMedium,
            ),
            child: Row(
              children: [
                // ── Icon badge ──────────────────────
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryWithOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: Icon(
                    _iconForType(type),
                    size: AppDimensions.iconSizeMedium,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),

                // ── Label + description ─────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyles.labelLarge),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),

                // ── Value + chevron ─────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingXS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithOpacity(0.08),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusSmall,
                        ),
                        border: Border.all(
                          color: AppColors.primaryWithOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        displayValue,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isEditable) ...[
                      const SizedBox(width: AppDimensions.paddingXS),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: AppDimensions.iconSizeSmall,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: AppDimensions.cardPaddingMedium,
            endIndent: AppDimensions.cardPaddingMedium,
            color: AppColors.divider,
          ),
      ],
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

  String _displayValue(String value, String type) {
    if (type == 'boolean') return _asBool(value) ? 'Enabled' : 'Disabled';
    return value.isEmpty ? '—' : value;
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