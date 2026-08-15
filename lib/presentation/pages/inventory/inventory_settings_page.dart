// lib/presentation/pages/inventory/inventory_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_message.dart';
import '../../../core/utils/toast_helper.dart';
import '../../providers/inventory/inventory_settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// Clinic-wide stock rules.
///
/// The endpoint requires a complete body, so this edits one whole settings
/// object and saves it in one go — a partial save would let a half-loaded form
/// write back over settings it never showed.
class InventorySettingsPage extends ConsumerStatefulWidget {
  const InventorySettingsPage({super.key});

  @override
  ConsumerState<InventorySettingsPage> createState() =>
      _InventorySettingsPageState();
}

class _InventorySettingsPageState
    extends ConsumerState<InventorySettingsPage> {
  InventorySettingsModel? _draft;
  bool _isSaving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(inventorySettingsWriterProvider).save(draft);

      ref.invalidate(inventorySettingsProvider);

      if (mounted) {
        ToastHelper.success(context, 'Inventory settings saved.');
      }
    } catch (e) {
      if (mounted) ToastHelper.fromError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(inventorySettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inventory Settings', style: AppTextStyles.titleMedium),
            Text(
              'Rules that apply across every branch',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(describeError(e)),
              const SizedBox(height: AppDimensions.paddingMedium),
              if (!isPermissionError(e))
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(inventorySettingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
            ],
          ),
        ),
        data: (loaded) {
          final settings = _draft ?? loaded;

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section('Automatic deduction'),
                    _SwitchTile(
                      title: 'Deduct stock automatically',
                      subtitle:
                          'When an appointment is completed, draw its supplies '
                          'from stock using each treatment\'s consumables list.',
                      value: settings.autoDeductEnabled,
                      onChanged: (value) => _update(
                        settings.copyWith(autoDeductEnabled: value),
                      ),
                    ),
                    _SwitchTile(
                      title: 'Allow negative stock',
                      subtitle:
                          'Record a shortfall when supplies run out rather '
                          'than hiding it. Either way an appointment is never '
                          'blocked by a stock number.',
                      value: settings.allowNegativeStock,
                      onChanged: (value) => _update(
                        settings.copyWith(allowNegativeStock: value),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.paddingLarge),
                    _section('Expiry'),
                    _SwitchTile(
                      title: 'Track expiry dates',
                      subtitle:
                          'Ask for an expiry date on incoming stock so lots '
                          'can be used earliest-first.',
                      value: settings.trackExpiry,
                      onChanged: (value) =>
                          _update(settings.copyWith(trackExpiry: value)),
                    ),
                    _NumberTile(
                      label: 'Warn this many days before expiry',
                      value: settings.expiryWarningDays,
                      min: 1,
                      max: 365,
                      onChanged: (value) =>
                          _update(settings.copyWith(expiryWarningDays: value)),
                    ),

                    const SizedBox(height: AppDimensions.paddingLarge),
                    _section('Reordering'),
                    _NumberTile(
                      label: 'Default reorder point',
                      helper: 'Used for items that do not set their own.',
                      value: settings.defaultMinimumThreshold,
                      min: 0,
                      max: 100000,
                      onChanged: (value) => _update(
                        settings.copyWith(defaultMinimumThreshold: value),
                      ),
                    ),
                    _SwitchTile(
                      title: 'Send low-stock alerts',
                      subtitle:
                          'A daily digest of items at or below their reorder '
                          'point, plus batches about to expire.',
                      value: settings.lowStockAlertsEnabled,
                      onChanged: (value) => _update(
                        settings.copyWith(lowStockAlertsEnabled: value),
                      ),
                    ),
                    _NumberTile(
                      label: 'Send the digest at (hour, 0-23)',
                      value: settings.lowStockAlertHour,
                      min: 0,
                      max: 23,
                      onChanged: (value) =>
                          _update(settings.copyWith(lowStockAlertHour: value)),
                    ),
                    _NumberTile(
                      label: 'Days before alerting on the same item again',
                      value: settings.lowStockCooldownDays,
                      min: 0,
                      max: 90,
                      onChanged: (value) => _update(
                        settings.copyWith(lowStockCooldownDays: value),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.paddingLarge),
                    ElevatedButton.icon(
                      onPressed: _isSaving || _draft == null ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : _draft == null
                                ? 'No changes'
                                : 'Save settings',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingMedium,
                        ),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _update(InventorySettingsModel next) => setState(() => _draft = next);

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: AppColors.primary),
          const SizedBox(width: AppDimensions.paddingSmall),
          Text(
            label,
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Wrapped in its own Material so the tile's ink and background paint on a
    // surface of their own rather than through the bordered container.
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          activeThumbColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _NumberTile extends StatefulWidget {
  final String label;
  final String? helper;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberTile({
    required this.label,
    this.helper,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_NumberTile> createState() => _NumberTileState();
}

class _NumberTileState extends State<_NumberTile> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value.toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helper,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
        onChanged: (raw) {
          final parsed = int.tryParse(raw);

          // Out-of-range values are simply not reported: the server rejects
          // them anyway, and holding one would only fail on save.
          if (parsed != null && parsed >= widget.min && parsed <= widget.max) {
            widget.onChanged(parsed);
          }
        },
      ),
    );
  }
}
