// lib/presentation/pages/patients/patients_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/patient/patient_list_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

class PatientsListPage extends ConsumerWidget {
  const PatientsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientListProvider);
    final notifier = ref.read(patientListProvider.notifier);
    final permissions = ref.watch(permissionServiceProvider);

    final canCreate = permissions.can(Perm.patientCreate);
    final canUpdate = permissions.can(Perm.patientUpdate);
    final canDelete = permissions.can(Perm.patientDelete);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(canCreate: canCreate),
          const SizedBox(height: AppDimensions.paddingLarge),
          _SearchBar(onChanged: notifier.search),
          const SizedBox(height: AppDimensions.paddingMedium),
          if (!state.isLoading && state.errorMessage == null)
            _Toolbar(state: state, notifier: notifier),
          Expanded(
            child: _Body(
              state: state,
              notifier: notifier,
              canUpdate: canUpdate,
              canDelete: canDelete,
            ),
          ),
          if (!state.isLoading &&
              state.errorMessage == null &&
              state.patients.isNotEmpty)
            _PaginationBar(state: state, notifier: notifier),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool canCreate;
  const _Header({required this.canCreate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Patients', style: AppTextStyles.headlineMedium),
        if (canCreate)
          FilledButton.icon(
            onPressed: () => context.push('/patients/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Patient'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadius,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search patients...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ── Toolbar ───────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final PatientListState state;
  final PatientListNotifier notifier;
  const _Toolbar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${state.total} patient${state.total == 1 ? '' : 's'}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          _PerPageSelector(state: state, notifier: notifier),
        ],
      ),
    );
  }
}

class _PerPageSelector extends StatelessWidget {
  final PatientListState state;
  final PatientListNotifier notifier;
  const _PerPageSelector({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Rows per page: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<int>(
            value: state.perPage,
            dropdownColor: AppColors.background,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink),
            underline: const SizedBox(),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
            items: [5, 10, 20, 50]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                .toList(),
            onChanged: (v) {
              if (v != null) notifier.changePerPage(v);
            },
          ),
        ),
      ],
    );
  }
}

// ── Body ──────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final PatientListState state;
  final PatientListNotifier notifier;
  final bool canUpdate;
  final bool canDelete;

  const _Body({
    required this.state,
    required this.notifier,
    required this.canUpdate,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return _ErrorView(state: state, notifier: notifier);
    }
    if (state.patients.isEmpty) {
      return const _EmptyView();
    }
    return _PatientTable(
      state: state,
      canUpdate: canUpdate,
      canDelete: canDelete,
    );
  }
}

// ── Error / Empty ─────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final PatientListState state;
  final PatientListNotifier notifier;
  const _ErrorView({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: notifier.refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            color: AppColors.textTertiary,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'No patients found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Patient Table ─────────────────────────────────────────────
class _PatientTable extends StatelessWidget {
  final PatientListState state;
  final bool canUpdate;
  final bool canDelete;

  const _PatientTable({
    required this.state,
    required this.canUpdate,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 300,
            ),
            child: DataTable(
              columnSpacing: 32,
              horizontalMargin: 24,
              headingRowHeight: 52,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              headingRowColor:
                  WidgetStateProperty.all(AppColors.surface),
              dividerThickness: 0.5,
              columns: const [
                DataColumn(label: _HeaderCell('ID')),
                DataColumn(label: _HeaderCell('Name')),
                DataColumn(label: _HeaderCell('Email')),
                DataColumn(label: _HeaderCell('Phone')),
                DataColumn(label: _HeaderCell('Blood Type')),
                DataColumn(label: _HeaderCell('Actions')),
              ],
              rows: state.patients.map((patient) {
                return DataRow(
                  cells: [
                    DataCell(_bodyText('${patient.id}')),
                    DataCell(_bodyText(patient.name, bold: true)),
                    DataCell(_bodyText(patient.email)),
                    DataCell(_bodyText(patient.phone ?? '—')),
                    DataCell(
                      _BloodTypeChip(
                        bloodType: patient.patientProfile.bloodType,
                      ),
                    ),
                    DataCell(
                      _ActionButtons(
                        patientId: patient.id,
                        canUpdate: canUpdate,
                        canDelete: canDelete,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bodyText(String text, {bool bold = false}) {
    return Text(
      text,
      style: TextStyle(
        color: bold ? AppColors.ink : AppColors.textSecondary,
        fontSize: 13,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

// ── Blood Type Chip ───────────────────────────────────────────
class _BloodTypeChip extends StatelessWidget {
  final String? bloodType;
  const _BloodTypeChip({this.bloodType});

  @override
  Widget build(BuildContext context) {
    if (bloodType == null || bloodType!.isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        bloodType!,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────
class _ActionButtons extends ConsumerWidget {
  final int patientId;
  final bool canUpdate;
  final bool canDelete;

  const _ActionButtons({
    required this.patientId,
    required this.canUpdate,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.visibility_outlined,
          color: AppColors.info,
          tooltip: 'View',
          onPressed: () => context.push('/patients/$patientId'),
        ),
        if (canUpdate) ...[
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.edit_outlined,
            color: AppColors.warning,
            tooltip: 'Edit',
            onPressed: () => context.push('/patients/$patientId/edit'),
          ),
        ],
        if (canDelete) ...[
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.delete_outline,
            color: AppColors.error,
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        title: Text('Delete Patient?', style: AppTextStyles.titleMedium),
        content: Text(
          'This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(patientListProvider.notifier).delete(patientId);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ── Pagination ────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final PatientListState state;
  final PatientListNotifier notifier;

  const _PaginationBar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final current = state.currentPage;
    final last = state.lastPage;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.paddingMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page $current of $last',
              style: AppTextStyles.bodySmall,
            ),
            _PageControls(state: state, notifier: notifier),
            Text(_rangeText(), style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  String _rangeText() {
    if (state.total == 0) return 'Showing 0';
    final start = (state.currentPage - 1) * state.perPage + 1;
    final end = start + state.patients.length - 1;
    return 'Showing $start–$end of ${state.total}';
  }
}

class _PageControls extends StatelessWidget {
  final PatientListState state;
  final PatientListNotifier notifier;
  const _PageControls({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final current = state.currentPage;
    final last = state.lastPage;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(
          icon: Icons.first_page,
          tooltip: 'First',
          enabled: current > 1,
          onPressed: () => notifier.goToPage(1),
        ),
        const SizedBox(width: 4),
        _NavButton(
          icon: Icons.chevron_left,
          tooltip: 'Previous',
          enabled: current > 1,
          onPressed: notifier.previousPage,
        ),
        const SizedBox(width: 8),
        ..._buildPagePills(current, last),
        const SizedBox(width: 8),
        _NavButton(
          icon: Icons.chevron_right,
          tooltip: 'Next',
          enabled: state.hasMore,
          onPressed: notifier.nextPage,
        ),
        const SizedBox(width: 4),
        _NavButton(
          icon: Icons.last_page,
          tooltip: 'Last',
          enabled: current < last,
          onPressed: () => notifier.goToPage(last),
        ),
      ],
    );
  }

  List<Widget> _buildPagePills(int current, int last) {
    final pages = <int>{1, last};
    for (int i = current - 1; i <= current + 1; i++) {
      if (i >= 1 && i <= last) pages.add(i);
    }
    final sorted = pages.toList()..sort();

    final widgets = <Widget>[];
    int? prev;

    for (final page in sorted) {
      if (prev != null && page - prev > 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('…', style: TextStyle(color: AppColors.textTertiary)),
        ));
      }

      final isActive = page == current;
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: isActive ? null : () => notifier.goToPage(page),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$page',
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontWeight:
                      isActive ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
      prev = page;
    }
    return widgets;
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: enabled ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? AppColors.border : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.textSecondary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ── Header Cell ───────────────────────────────────────────────
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
  }
}