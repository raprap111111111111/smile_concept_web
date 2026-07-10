// lib/presentation/pages/patients/patients_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/patient/patient_list_provider.dart';
import '../../theme/app_colors.dart';

class PatientsListPage extends ConsumerWidget {
  const PatientsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientListProvider);
    final notifier = ref.read(patientListProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Patients',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/patients/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Search ─────────────────────────────────────
          TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => notifier.search(v),
            decoration: InputDecoration(
              hintText: 'Search patients...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: AppColors.surfaceDark,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Toolbar: Total + Per-Page ───────────────────
          if (!state.isLoading && state.errorMessage == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${state.total} patient${state.total == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Rows per page: ',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: DropdownButton<int>(
                          value: state.perPage,
                          dropdownColor: AppColors.surfaceDark,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white54,
                            size: 20,
                          ),
                          items: [5, 10, 20, 50].map((v) {
                            return DropdownMenuItem(
                              value: v,
                              child: Text('$v'),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) notifier.changePerPage(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ─── Table (scrollable) ──────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                    ? _buildError(state, notifier)
                    : state.patients.isEmpty
                        ? _buildEmpty()
                        : _buildTable(context, ref, state),
          ),

          // ─── Pagination Controls ─────────────────────────
          if (!state.isLoading &&
              state.errorMessage == null &&
              state.patients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildPaginationControls(context, ref, state),
            ),
        ],
      ),
    );
  }

  // ─── Error State ──────────────────────────────────────────
  Widget _buildError(PatientListState state, PatientListNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: notifier.refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people_outline, color: Colors.white24, size: 64),
          SizedBox(height: 12),
          Text(
            'No patients found',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ─── Table ────────────────────────────────────────────────
  Widget _buildTable(
    BuildContext context,
    WidgetRef ref,
    PatientListState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
              headingRowColor: WidgetStateProperty.all(
                Colors.white.withValues(alpha: 0.04),
              ),
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
                    DataCell(
                      Text(
                        '${patient.id}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        patient.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        patient.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        patient.phone ?? '—',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(_bloodTypeChip(patient.patientProfile.bloodType)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _actionButton(
                            icon: Icons.visibility_outlined,
                            color: Colors.blueAccent,
                            tooltip: 'View',
                            onPressed: () =>
                                context.push('/patients/${patient.id}'),
                          ),
                          const SizedBox(width: 4),
                          _actionButton(
                            icon: Icons.edit_outlined,
                            color: Colors.orangeAccent,
                            tooltip: 'Edit',
                            onPressed: () =>
                                context.push('/patients/${patient.id}/edit'),
                          ),
                          const SizedBox(width: 4),
                          _actionButton(
                            icon: Icons.delete_outline,
                            color: Colors.redAccent,
                            tooltip: 'Delete',
                            onPressed: () =>
                                _confirmDelete(context, ref, patient.id),
                          ),
                        ],
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

  // ─── Blood Type Chip ──────────────────────────────────────
  Widget _bloodTypeChip(String? bloodType) {
    if (bloodType == null || bloodType.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(color: Colors.white38, fontSize: 13),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Text(
        bloodType,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ─── Action Icon Button ───────────────────────────────────
  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
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

  // ─── Pagination Controls ──────────────────────────────────
  Widget _buildPaginationControls(
    BuildContext context,
    WidgetRef ref,
    PatientListState state,
  ) {
    final notifier = ref.read(patientListProvider.notifier);
    final current = state.currentPage;
    final last = state.lastPage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left: page info ──
          Text(
            'Page $current of $last',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),

          // ── Center: pagination controls ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navButton(
                icon: Icons.first_page,
                tooltip: 'First page',
                enabled: current > 1,
                onPressed: () => notifier.goToPage(1),
              ),
              const SizedBox(width: 4),
              _navButton(
                icon: Icons.chevron_left,
                tooltip: 'Previous page',
                enabled: current > 1,
                onPressed: notifier.previousPage,
              ),
              const SizedBox(width: 8),
              ..._buildPagePills(current, last, notifier),
              const SizedBox(width: 8),
              _navButton(
                icon: Icons.chevron_right,
                tooltip: 'Next page',
                enabled: state.hasMore,
                onPressed: notifier.nextPage,
              ),
              const SizedBox(width: 4),
              _navButton(
                icon: Icons.last_page,
                tooltip: 'Last page',
                enabled: current < last,
                onPressed: () => notifier.goToPage(last),
              ),
            ],
          ),

          // ── Right: showing X-Y of Z ──
          Text(
            _rangeText(state),
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _rangeText(PatientListState state) {
    if (state.total == 0) return 'Showing 0';
    final start = (state.currentPage - 1) * state.perPage + 1;
    final end = start + state.patients.length - 1;
    return 'Showing $start–$end of ${state.total}';
  }

  Widget _navButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled ? Colors.white70 : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPagePills(
    int current,
    int last,
    PatientListNotifier notifier,
  ) {
    final Set<int> pagesToShow = {1, last};
    for (int i = current - 1; i <= current + 1; i++) {
      if (i >= 1 && i <= last) pagesToShow.add(i);
    }
    final sorted = pagesToShow.toList()..sort();

    final List<Widget> pills = [];
    int? prev;

    for (final page in sorted) {
      if (prev != null && page - prev > 1) {
        pills.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '…',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ),
        );
      }

      final isActive = page == current;

      pills.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isActive ? null : () => notifier.goToPage(page),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$page',
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white70,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      prev = page;
    }

    return pills;
  }

  // ─── Delete Confirmation ──────────────────────────────────
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Delete Patient?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(patientListProvider.notifier).delete(id);
    }
  }
}

// ─── Reusable Header Cell ───────────────────────────────────
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}