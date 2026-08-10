// lib/presentation/pages/settings/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/setting_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SettingsHeader(),
            const SizedBox(height: AppDimensions.paddingXL),
            Expanded(
              child: settingsAsync.when(
                data: (settings) {
                  if (settings.isEmpty) return const _EmptyState();

                  final grouped = _groupSettings(settings);

                  return ListView(
                    children: grouped.entries.map((entry) {
                      return _SettingsGroup(
                        groupName: entry.key,
                        items: entry.value,
                        onEdit: (setting) => _showEditDialog(
                          context,
                          ref,
                          setting,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const _LoadingView(),
                error: (error, _) => _ErrorView(message: error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupSettings(
    List<Map<String, dynamic>> settings,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final setting in settings) {
      final group = setting['group']?.toString() ?? 'general';
      grouped.putIfAbsent(group, () => []);
      grouped[group]!.add(setting);
    }
    return grouped;
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> setting,
  ) {
    showDialog(
      context: context,
      builder: (_) => _EditSettingDialog(
        setting: setting,
        onSave: (key, value) async {
          final repo = ref.read(settingRepositoryProvider);
          await repo.updateSetting(key, {'value': value});
          ref.invalidate(settingsProvider);
        },
      ),
    );
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppDimensions.iconBadgeSize,
          height: AppDimensions.iconBadgeSize,
          decoration: BoxDecoration(
            color: AppColors.primaryWithOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: AppColors.primary,
            size: AppDimensions.iconSize,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: AppTextStyles.titleLarge),
            Text(
              'Configure system-wide preferences',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Settings Group ───────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.groupName,
    required this.items,
    required this.onEdit,
  });

  final String groupName;
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupLabel(label: groupName),
          const SizedBox(height: AppDimensions.paddingMedium),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final isLast = entry.key == items.length - 1;
                return _SettingTile(
                  setting: entry.value,
                  showDivider: !isLast,
                  onTap: () => onEdit(entry.value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.replaceAll('_', ' ').toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingXS),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}

// ─── Setting Tile ─────────────────────────────────────────────────────────────

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.setting,
    required this.showDivider,
    required this.onTap,
  });

  final Map<String, dynamic> setting;
  final bool showDivider;
  final VoidCallback onTap;

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
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
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
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadius,
                    ),
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

// ─── Edit Dialog ──────────────────────────────────────────────────────────────

class _EditSettingDialog extends StatefulWidget {
  const _EditSettingDialog({
    required this.setting,
    required this.onSave,
  });

  final Map<String, dynamic> setting;
  final Future<void> Function(String key, String value) onSave;

  @override
  State<_EditSettingDialog> createState() => _EditSettingDialogState();
}

class _EditSettingDialogState extends State<_EditSettingDialog> {
  late final TextEditingController _controller;
  late bool _boolValue;
  bool _isSaving = false;

  String get _type => widget.setting['type']?.toString() ?? 'string';
  String get _key => widget.setting['key']?.toString() ?? '';
  String get _label =>
      widget.setting['label']?.toString() ?? _key;

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
      _showSnack('Error: $error', AppColors.error);
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

// ─── Boolean Toggle ───────────────────────────────────────────────────────────

class _BooleanToggle extends StatelessWidget {
  const _BooleanToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

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
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusSmall,
              ),
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
            inactiveTrackColor: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

// ─── Loading / Error / Empty ──────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Loading settings...',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusLarge,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text('Something went wrong', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.06),
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusLarge,
              ),
              border: Border.all(
                color: AppColors.primaryWithOpacity(0.12),
              ),
            ),
            child: const Icon(
              Icons.settings_rounded,
              size: 38,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text('No settings found', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            'System settings will appear here once configured.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}