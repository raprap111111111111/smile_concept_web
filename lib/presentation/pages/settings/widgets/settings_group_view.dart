// lib/presentation/pages/settings/widgets/settings_group_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';

import '../../../providers/setting/setting_provider.dart';   // ✅ NEW
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import 'edit_setting_dialog.dart';
import 'setting_tile.dart';

class SettingsGroupView extends ConsumerWidget {
  final List<String> filterGroups;

  const SettingsGroupView({super.key, required this.filterGroups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Watch the notifier state
    final state = ref.watch(settingNotifierProvider);

    // Loading
    if (state.isLoading && state.settings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Error
    if (state.error != null && state.settings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              describeError(state.error!),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () =>
                  ref.read(settingNotifierProvider.notifier).load(),
            ),
          ],
        ),
      );
    }

    // ✅ Filter using the notifier's helper
    final filtered =
        ref.read(settingNotifierProvider.notifier).filterByGroups(filterGroups);

    if (filtered.isEmpty) return const _EmptyState();

    final grouped = _groupSettings(filtered);

    return ListView(
      padding: EdgeInsets.zero,
      children: grouped.entries.map((entry) {
        return _SettingsGroup(
          groupName: entry.key,
          items: entry.value,
          onEdit: (setting) => _showEditDialog(context, ref, setting),
        );
      }).toList(),
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
      builder: (_) => EditSettingDialog(
        setting: setting,
        onSave: (key, value) async {
          // ✅ Use the notifier — handles state update automatically
          await ref
              .read(settingNotifierProvider.notifier)
              .updateSetting(key, value);
        },
      ),
    );
  }
}

// ─── Settings Group ───────────────────────────────────────────
class _SettingsGroup extends StatelessWidget {
  final String groupName;
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const _SettingsGroup({
    required this.groupName,
    required this.items,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                groupName.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingXS),
              const Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),
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
                return SettingTile(
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

// ─── Empty State ──────────────────────────────────────────────
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
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 38,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text('No settings in this section',
              style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            'Settings will appear here once configured.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}