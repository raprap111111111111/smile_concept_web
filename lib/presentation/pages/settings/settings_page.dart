import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/setting_repository.dart';
import '../../theme/app_colors.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            Expanded(
              child: settingsAsync.when(
                data: (settings) {
                  if (settings.isEmpty) {
                    return _emptyState();
                  }

                  final grouped = _groupSettings(settings);

                  return ListView(
                    children: grouped.entries.map((entry) {
                      final group = entry.key;
                      final items = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(group),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: items.map((setting) {
                                return _buildSettingCard(
                                  context,
                                  ref,
                                  setting,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7C3AED),
                Color(0xFF4F46E5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.settings,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Configure system-wide preferences',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.replaceAll('_', ' ').toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> setting,
  ) {
    final label = setting['label']?.toString() ??
        setting['key']?.toString() ??
        'Setting';

    final description = setting['description']?.toString() ?? '';
    final value = setting['value']?.toString() ?? '';
    final type = setting['type']?.toString() ?? 'string';
    final isEditable = _asBool(setting['is_editable'], fallback: true);

    return MouseRegion(
      cursor: isEditable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        onTap: isEditable
            ? () => _showEditSettingDialog(context, ref, setting)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(type),
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _displayValue(value, type),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'boolean':
        return Icons.toggle_on_outlined;
      case 'integer':
      case 'float':
        return Icons.numbers_outlined;
      case 'json':
        return Icons.data_object_outlined;
      case 'date':
        return Icons.calendar_today_outlined;
      default:
        return Icons.tune;
    }
  }

  String _displayValue(String value, String type) {
    if (type == 'boolean') {
      return _asBool(value) ? 'Enabled' : 'Disabled';
    }

    return value;
  }

  void _showEditSettingDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> setting,
  ) {
    final key = setting['key']?.toString();

    if (key == null || key.isEmpty) return;

    final type = setting['type']?.toString() ?? 'string';

    final controller = TextEditingController(
      text: setting['value']?.toString() ?? '',
    );

    bool boolValue = _asBool(setting['value']);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Text(
                setting['label']?.toString() ?? key,
                style: const TextStyle(color: Colors.white),
              ),
              content: type == 'boolean'
                  ? SwitchListTile(
                      title: const Text(
                        'Enabled',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: boolValue,
                      onChanged: (value) {
                        setDialogState(() {
                          boolValue = value;
                        });
                      },
                    )
                  : TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Value',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final repo = ref.read(settingRepositoryProvider);

                      final value = type == 'boolean'
                          ? (boolValue ? '1' : '0')
                          : controller.text.trim();

                      await repo.updateSetting(
                        key,
                        {
                          'value': value,
                        },
                      );

                      ref.invalidate(settingsProvider);

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('Setting updated'),
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('Error: $error'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No settings found',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
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