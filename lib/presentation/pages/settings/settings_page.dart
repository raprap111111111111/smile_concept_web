// lib/presentation/pages/settings/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'tabs/appointment_settings_tab.dart';
import 'tabs/inventory_settings_tab.dart';

class SettingsPage extends ConsumerStatefulWidget {
  final String? initialTab;

  const SettingsPage({super.key, this.initialTab});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late int _selectedIndex;

  final _tabs = const [
    _SettingsTab(
      key: 'appointments',
      icon: Icons.calendar_today_outlined,
      label: 'Appointments',
      description: 'Booking rules, slot duration',
      page: AppointmentSettingsTab(),
    ),
    _SettingsTab(
      key: 'inventory',
      icon: Icons.inventory_2_outlined,
      label: 'Inventory',
      description: 'Stock alerts, thresholds',
      page: InventorySettingsTab(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _findTabIndex(widget.initialTab);
  }

  int _findTabIndex(String? key) {
    if (key == null) return 0;
    final idx = _tabs.indexWhere((t) => t.key == key);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 900;

                  return isCompact
                      ? _buildCompactLayout()
                      : _buildWideLayout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // Wide layout (Desktop) — sidebar tabs on left
  // ══════════════════════════════════════════════════════════
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left rail
        SizedBox(
          width: 260,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusLarge,
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _tabs.length; i++)
                  _buildTabTile(_tabs[i], i, showDescription: true),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingLarge),

        // Right content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: _tabs[_selectedIndex].page,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // Compact layout (Mobile/Tablet) — top tabs
  // ══════════════════════════════════════════════════════════
  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < _tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChipTab(_tabs[i], i),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingLarge),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: _tabs[_selectedIndex].page,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // Tab widgets
  // ══════════════════════════════════════════════════════════
  Widget _buildTabTile(
    _SettingsTab tab,
    int index, {
    bool showDescription = false,
  }) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryWithOpacity(0.08)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                tab.icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (showDescription) ...[
                      const SizedBox(height: 2),
                      Text(
                        tab.description,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipTab(_SettingsTab tab, int index) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: isSelected
          ? AppColors.primaryWithOpacity(0.1)
          : AppColors.background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 16,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab config ───────────────────────────────────────────────
class _SettingsTab {
  final String key;
  final IconData icon;
  final String label;
  final String description;
  final Widget page;

  const _SettingsTab({
    required this.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.page,
  });
}

// ─── Header ───────────────────────────────────────────────────
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