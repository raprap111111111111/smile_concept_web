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
import '../../widgets/shared/search_bar_onclick.dart';

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
          // ✅ Replaced _SearchBar with shared SearchBarOnClick
          SearchBarOnClick(
            hintText: 'Search patients...',
            onChanged: notifier.search,
            onClear: () => notifier.search(''),
          ),
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
      return const _TableSkeleton();
    }
    if (state.errorMessage != null) {
      return _ErrorView(state: state, notifier: notifier);
    }
    if (state.patients.isEmpty) {
      return _EmptyView(searchQuery: state.searchQuery);
    }
    return _PatientTable(
      state: state,
      canUpdate: canUpdate,
      canDelete: canDelete,
    );
  }
}

// ── Loading Skeleton ──────────────────────────────────────────
/// Holds the table's shape while the page loads so the row area does not
/// collapse to a spinner and then shove the pagination bar back down. Static
/// on purpose — a shimmer here would never settle for `pumpAndSettle`.
class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Only as many placeholder rows as the box can hold. A fixed count
          // overflows the short viewports this page is also rendered into.
          final rows = constraints.maxHeight.isFinite
              ? ((constraints.maxHeight - _kHeadingRowHeight) /
                      _kDataRowMinHeight)
                  .floor()
                  .clamp(1, 8)
              : 6;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: _kHeadingRowHeight,
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: _kHorizontalMargin,
                ),
                alignment: Alignment.centerLeft,
                child: const _SkeletonBar(width: 120, height: 10),
              ),
              for (var i = 0; i < rows; i++)
                Container(
                  height: _kDataRowMinHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _kHorizontalMargin,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.line, width: 0.5),
                    ),
                  ),
                  child: const Row(
                    children: [
                      _SkeletonBar(width: 34, height: 34, radius: 17),
                      SizedBox(width: 12),
                      _SkeletonBar(width: 140, height: 12),
                      SizedBox(width: 40),
                      _SkeletonBar(width: 180, height: 12),
                      SizedBox(width: 40),
                      _SkeletonBar(width: 100, height: 12),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBar({
    required this.width,
    required this.height,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
      ),
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
  final String searchQuery;
  const _EmptyView({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final searching = searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              searching ? Icons.search_off : Icons.people_outline,
              color: AppColors.textSecondary,
              size: 34,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            searching ? 'No matches for "$searchQuery"' : 'No patients yet',
            style: AppTextStyles.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          // An empty table says nothing about what to do next; both branches
          // name the one action that clears the state.
          Text(
            searching
                ? 'Check the spelling, or clear the search to see everyone.'
                : 'Patients you add will be listed here.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Patient Table ─────────────────────────────────────────────
const double _kHeadingRowHeight = 48;
const double _kDataRowMinHeight = 64;
const double _kHorizontalMargin = 24;

/// The bordered, clipped card every table state is drawn inside, so the
/// skeleton and the loaded table share one outline instead of two that drift.
class _TableShell extends StatelessWidget {
  final Widget child;
  const _TableShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(alignment: Alignment.topLeft, child: child),
    );
  }
}

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
    return _TableShell(
      // LayoutBuilder rather than `screen width - 300`: the sidebar collapses
      // to 84px, and the old constant left the table 200px short of the space
      // it had, stranding the Actions column mid-row.
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 28,
                  horizontalMargin: _kHorizontalMargin,
                  headingRowHeight: _kHeadingRowHeight,
                  dataRowMinHeight: _kDataRowMinHeight,
                  dataRowMaxHeight: 72,
                  // Every row is tappable, which would otherwise make
                  // DataTable grow a checkbox column nobody asked for.
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(AppColors.surface),
                  dividerThickness: 0.5,
                  columns: const [
                    DataColumn(label: _HeaderCell('Name')),
                    DataColumn(label: _HeaderCell('Email')),
                    DataColumn(label: _HeaderCell('Phone')),
                    DataColumn(label: _HeaderCell('Blood Type')),
                    DataColumn(label: _HeaderCell('Actions')),
                  ],
                  rows: state.patients.map((patient) {
                    return DataRow(
                      key: ValueKey(patient.id),
                      // Reading a patient took a hit on an 18px eye icon. The
                      // whole row now opens the record — the icon stays for
                      // discoverability and keyboard reach.
                      onSelectChanged: (_) =>
                          context.push('/patients/${patient.id}'),
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return AppColors.primary.withValues(alpha: 0.05);
                        }
                        return null;
                      }),
                      cells: [
                        DataCell(_NameCell(name: patient.name)),
                        DataCell(_CellText(patient.email)),
                        DataCell(_CellText(patient.phone)),
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
          );
        },
      ),
    );
  }
}

// ── Cells ─────────────────────────────────────────────────────
/// Name paired with an initials avatar. Rows of near-identical text are hard
/// to track across; the avatar gives the eye something to anchor on.
class _NameCell extends StatelessWidget {
  final String name;
  const _NameCell({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accentLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials(name),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

/// Secondary column value. A missing one prints an em dash rather than a
/// lighter grey — the glyph carries the meaning, so it does not rest on a
/// colour difference that would have to fail contrast to be visible.
class _CellText extends StatelessWidget {
  final String? value;
  const _CellText(this.value);

  @override
  Widget build(BuildContext context) {
    final filled = value != null && value!.isNotEmpty;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Text(
        filled ? value! : '—',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
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
      return const _CellText(null);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bloodTypeSoft,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: AppColors.bloodTypeInk.withValues(alpha: 0.2)),
      ),
      child: Text(
        bloodType!,
        style: const TextStyle(
          color: AppColors.bloodTypeInk,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
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
          color: AppColors.actionViewInk,
          tooltip: 'View',
          onPressed: () => context.push('/patients/$patientId'),
        ),
        if (canUpdate)
          _ActionButton(
            icon: Icons.edit_outlined,
            color: AppColors.actionEditInk,
            tooltip: 'Edit',
            onPressed: () => context.push('/patients/$patientId/edit'),
          ),
        if (canDelete)
          _ActionButton(
            icon: Icons.delete_outline,
            color: AppColors.actionDeleteInk,
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
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

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // 44x44 of tappable area around a 34x34 chip: the old control was 30px
    // square with 4px between neighbours, so Delete sat one slip away from
    // Edit. The padding is transparent, so the row still looks compact.
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: InkResponse(
          onTap: widget.onPressed,
          onHover: (hovering) => setState(() => _hovered = hovering),
          radius: 22,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: _hovered ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusSmall,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: AppDimensions.iconSizeSmall,
                ),
              ),
            ),
          ),
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
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Page $current of $last', style: AppTextStyles.bodySmall),
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
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
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
/// Small caps in the secondary ink. The headers were the same size and weight
/// as the names beneath them, so the label row competed with the data instead
/// of framing it.
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w800,
        fontSize: 12,
        letterSpacing: 0.8,
      ),
    );
  }
}