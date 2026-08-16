// lib/presentation/pages/settings/tabs/inventory_settings_tab.dart

import 'package:flutter/material.dart';
import '../../inventory/inventory_settings_page.dart';

/// Wraps the existing InventorySettingsPage as a tab in the unified Settings page.
class InventorySettingsTab extends StatelessWidget {
  const InventorySettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const InventorySettingsPage();
  }
}