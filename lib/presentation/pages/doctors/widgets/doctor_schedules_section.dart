import 'package:flutter/material.dart';

import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';

class DoctorSchedulesSection extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorSchedulesSection({super.key, required this.doctor});

  @override
  State<DoctorSchedulesSection> createState() => _DoctorSchedulesSectionState();
}

class _DoctorSchedulesSectionState extends State<DoctorSchedulesSection> {
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String? _selectedBranchId; // ✅ null = "All branches"

  @override
  Widget build(BuildContext context) {
    final allSchedules =
        (widget.doctor['schedules'] as List? ?? []).cast<dynamic>();

    // ✅ Get unique branches from schedules
    final branches = _extractBranches(allSchedules);

    // ✅ Filter schedules based on selected branch
    final filteredSchedules = _selectedBranchId == null
        ? allSchedules
        : allSchedules.where((s) {
            final branchId = s['branch']?['id']?.toString();
            return branchId == _selectedBranchId;
          }).toList();

    // ✅ Group by day of week
    final grouped = _groupByDay(filteredSchedules);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(branches, filteredSchedules.length),
          const SizedBox(height: 12),
          if (allSchedules.isEmpty)
            _buildEmptyState('No schedules set')
          else if (filteredSchedules.isEmpty)
            _buildEmptyState('No schedules for this branch')
          else
            ..._buildScheduleList(grouped),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // Header (title + branch filter)
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(
    List<Map<String, String>> branches,
    int visibleCount,
  ) {
    return Row(
      children: [
        const Icon(Icons.calendar_month_outlined,
            size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('Weekly Schedule', style: AppTextStyles.titleSmall),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$visibleCount',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),

        // ✅ Branch filter dropdown (only show if there are 2+ branches)
        if (branches.length > 1) _buildBranchFilter(branches),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
// Branch Filter Dropdown
// ══════════════════════════════════════════════════════════
  Widget _buildBranchFilter(List<Map<String, String>> branches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedBranchId,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down,
              size: 18, color: AppColors.textSecondary),

          // ✅ WHITE dropdown menu
          dropdownColor: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),

          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),

          // ✅ Selected item shown in the button (compact style)
          selectedItemBuilder: (context) {
            return [
              _buildSelectedItem(
                icon: Icons.filter_list,
                label: 'All Branches',
              ),
              ...branches.map(
                (b) => _buildSelectedItem(
                  icon: Icons.business_outlined,
                  label: b['name']!,
                ),
              ),
            ];
          },

          items: [
            // ─── All Branches ───
            DropdownMenuItem<String?>(
              value: null,
              child: _buildMenuItem(
                icon: Icons.filter_list,
                label: 'All Branches',
                isSelected: _selectedBranchId == null,
              ),
            ),
            // ─── Individual Branches ───
            ...branches.map(
              (b) => DropdownMenuItem<String?>(
                value: b['id'],
                child: _buildMenuItem(
                  icon: Icons.business_outlined,
                  label: b['name']!,
                  isSelected: _selectedBranchId == b['id'],
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedBranchId = value);
          },
        ),
      ),
    );
  }

// ✅ How each item appears INSIDE the dropdown menu (white background)
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isSelected ? AppColors.primary : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : Colors.grey.shade800,
          ),
        ),
        if (isSelected) ...[
          const SizedBox(width: 8),
          Icon(Icons.check, size: 14, color: AppColors.primary),
        ],
      ],
    );
  }

// ✅ How the selected item appears in the CLOSED button
  Widget _buildSelectedItem({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // Empty State
  // ══════════════════════════════════════════════════════════
  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined,
                size: 32,
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // Schedule List — grouped by day
  // ══════════════════════════════════════════════════════════
  List<Widget> _buildScheduleList(Map<int, List<dynamic>> grouped) {
    final widgets = <Widget>[];

    // Only show days that have schedules
    final activeDays = grouped.keys.toList()..sort();

    for (final day in activeDays) {
      final schedules = grouped[day]!;
      widgets.add(_buildDayRow(day, schedules));
    }

    return widgets;
  }

  Widget _buildDayRow(int dayIndex, List<dynamic> schedules) {
    final day = _weekdays[dayIndex.clamp(0, 6)];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day label
          SizedBox(
            width: 90,
            child: Text(
              day,
              style:
                  AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          // Time slots
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: schedules.map(_buildTimeSlot).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(dynamic schedule) {
    final startTime = _formatTime(schedule['start_time']?.toString() ?? '');
    final endTime = _formatTime(schedule['end_time']?.toString() ?? '');
    final branch = schedule['branch']?['name']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.access_time,
              size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('$startTime - $endTime', style: AppTextStyles.bodySmall),
          if (branch.isNotEmpty) ...[
            const SizedBox(width: 12),
            const Icon(Icons.business_outlined,
                size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                branch,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════

  /// Extract unique branches from schedules for the filter dropdown.
  List<Map<String, String>> _extractBranches(List<dynamic> schedules) {
    final Map<String, String> unique = {};

    for (final s in schedules) {
      final branch = s['branch'];
      if (branch is Map && branch['id'] != null && branch['name'] != null) {
        unique[branch['id'].toString()] = branch['name'].toString();
      }
    }

    return unique.entries.map((e) => {'id': e.key, 'name': e.value}).toList()
      ..sort((a, b) => a['name']!.compareTo(b['name']!));
  }

  /// Group schedules by day of week for cleaner display.
  Map<int, List<dynamic>> _groupByDay(List<dynamic> schedules) {
    final grouped = <int, List<dynamic>>{};

    for (final s in schedules) {
      final day = s['day_of_week'] as int? ?? 0;
      grouped.putIfAbsent(day, () => []).add(s);
    }

    // Sort each day's slots by start time
    for (final list in grouped.values) {
      list.sort((a, b) => (a['start_time']?.toString() ?? '')
          .compareTo(b['start_time']?.toString() ?? ''));
    }

    return grouped;
  }

  /// Format "08:30:00" → "8:30 AM"
  String _formatTime(String time) {
    if (time.isEmpty || time == '--') return '--';

    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;

      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return '$displayHour:$minute $period';
    } catch (_) {
      return time;
    }
  }
}
