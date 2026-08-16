// lib/presentation/pages/settings/tabs/general_settings_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/settings_group_view.dart';

/// General settings tab — shows currency, tax, invoice prefix, etc.
class GeneralSettingsTab extends ConsumerWidget {
  const GeneralSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SettingsGroupView(
      // ✅ Only show groups that don't belong to appointment or inventory
      filterGroups: ['general', 'billing', 'branding', 'system'],
    );
  }
}