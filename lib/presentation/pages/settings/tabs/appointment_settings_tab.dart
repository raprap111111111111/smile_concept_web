// lib/presentation/pages/settings/tabs/appointment_settings_tab.dart

import 'package:flutter/material.dart';
import '../../appointment_settings/appointment_settings_page.dart';

/// Wraps the existing AppointmentSettingsPage as a tab in the unified Settings page.
class AppointmentSettingsTab extends StatelessWidget {
  const AppointmentSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppointmentSettingsPage();
  }
}