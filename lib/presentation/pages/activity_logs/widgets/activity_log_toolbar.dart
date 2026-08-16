import 'package:flutter/material.dart';

import '../../../providers/activity_log/activity_logs_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'activity_log_filter_dropdown.dart';

class ActivityLogToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final ActivityLogsParams filterState;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onActionChanged;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback onReset;

  const ActivityLogToolbar({
    super.key,
    required this.searchController,
    required this.filterState,
    required this.onSearchChanged,
    required this.onActionChanged,
    required this.onSubjectChanged,
    required this.onReset,
  });

  static const _actionItems = [
    DropdownMenuItem<String?>(value: null, child: Text('All actions')),
    DropdownMenuItem(value: 'created', child: Text('Created')),
    DropdownMenuItem(value: 'updated', child: Text('Updated')),
    DropdownMenuItem(value: 'deleted', child: Text('Deleted')),
    DropdownMenuItem(value: 'voided', child: Text('Voided')),
    DropdownMenuItem(value: 'signed', child: Text('Signed')),
    DropdownMenuItem(value: 'viewed', child: Text('Viewed')),
    DropdownMenuItem(value: 'logged_in', child: Text('Login')),
    DropdownMenuItem(value: 'logged_out', child: Text('Logout')),
  ];

  static const _subjectItems = [
    DropdownMenuItem<String?>(value: null, child: Text('All subjects')),
    DropdownMenuItem(
        value: 'App\\Models\\PatientConsent', child: Text('Consents')),
    DropdownMenuItem(
        value: 'App\\Models\\Appointment', child: Text('Appointments')),
    DropdownMenuItem(value: 'App\\Models\\User', child: Text('Users')),
    DropdownMenuItem(value: 'App\\Models\\Invoice', child: Text('Invoices')),
    DropdownMenuItem(
        value: 'App\\Models\\PatientProfile', child: Text('Patients')),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: AppDimensions.paddingSmall,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          return isCompact
              ? _buildCompactLayout()
              : _buildWideLayout();
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(child: _buildSearchField()),
        const SizedBox(width: 8),
        ActivityLogFilterDropdown<String?>(
          label: 'Action',
          value: filterState.action,
          items: _actionItems,
          onChanged: onActionChanged,
        ),
        const SizedBox(width: 8),
        ActivityLogFilterDropdown<String?>(
          label: 'Subject',
          value: filterState.subjectType,
          items: _subjectItems,
          onChanged: onSubjectChanged,
        ),
        const SizedBox(width: 8),
        _buildResetButton(),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      children: [
        _buildSearchField(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ActivityLogFilterDropdown<String?>(
                label: 'Action',
                value: filterState.action,
                items: _actionItems,
                onChanged: onActionChanged,
                fullWidth: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActivityLogFilterDropdown<String?>(
                label: 'Subject',
                value: filterState.subjectType,
                items: _subjectItems,
                onChanged: onSubjectChanged,
                fullWidth: true,
              ),
            ),
            const SizedBox(width: 8),
            _buildResetButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search action, subject, user…',
        prefixIcon: const Icon(Icons.search, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  searchController.clear();
                  onSearchChanged('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: IconButton(
        tooltip: 'Reset filters',
        icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
        onPressed: onReset,
      ),
    );
  }
}