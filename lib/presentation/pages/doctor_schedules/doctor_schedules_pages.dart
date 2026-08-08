// lib/presentation/pages/doctor_schedules/doctor_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../data/models/doctor_schedule/doctor_schedule_model.dart';
import '../../../data/repositories/doctor_schedule_repository.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/doctor_schedule/doctor_schedule_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/shared/hold_to_delete_dialog.dart';
import 'doctor_schedule_form_page.dart';
import 'widgets/day_filter_row.dart';
import 'widgets/schedule_card.dart';

class DoctorSchedulePage extends ConsumerStatefulWidget {
  final int? doctorId;
  final int? branchId;

  const DoctorSchedulePage({
    super.key,
    this.doctorId,
    this.branchId,
  });

  @override
  ConsumerState<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends ConsumerState<DoctorSchedulePage> {
  final ScrollController _scrollController = ScrollController();

  List<DoctorScheduleModel> _schedules = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  bool _hasNextPage = false;

  int? _filterDayOfWeek;

  DoctorScheduleRepository get _repository =>
      ref.read(doctorScheduleRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedules(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100;
    if (atBottom && !_isLoadingMore && _hasNextPage && !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadSchedules({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _schedules = [];
        _hasNextPage = false;
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    }

    try {
      final result = await _repository.getSchedules(
        page: _currentPage,
        doctorId: widget.doctorId,
        branchId: widget.branchId,
        dayOfWeek: _filterDayOfWeek,
      );

      final filteredRecords = _filterDayOfWeek == null
          ? result.data
          : result.data
              .where((schedule) => schedule.dayOfWeek == _filterDayOfWeek)
              .toList();

      if (!mounted) return;

      setState(() {
        if (reset) {
          _schedules = filteredRecords;
        } else {
          _schedules = [..._schedules, ...filteredRecords];
        }
        _hasNextPage = result.hasNextPage;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() => _currentPage++);
    await _loadSchedules(reset: false);
  }

  Future<void> _refresh() async {
    await _loadSchedules(reset: true);
  }

  Future<void> _deleteSchedule(DoctorScheduleModel schedule) async {
    final doctorName = schedule.doctor?.profile.name ?? 'this doctor';

    final confirmed = await HoldToDeleteDialog.show(
      context: context,
      title: 'Delete Schedule',
      itemName: '${schedule.dayLabel} schedule',
      description: 'You are about to delete the ${schedule.dayLabel} '
          'schedule for Dr. $doctorName. '
          'This will affect future appointment availability. '
          'This action cannot be undone.',
    );

    if (!confirmed) return;

    try {
      await _repository.deleteSchedule(schedule.id);
      if (!mounted) return;
      setState(() {
        _schedules.removeWhere((s) => s.id == schedule.id);
      });
      _showSnackBar('Schedule deleted successfully', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.of(context).push<DoctorScheduleModel>(
      MaterialPageRoute(
        builder: (_) => DoctorScheduleFormPage(
          prefillDoctorId: widget.doctorId,
          prefillBranchId: widget.branchId,
        ),
      ),
    );

    if (created == null || !mounted) return;

    if (_filterDayOfWeek == null || created.dayOfWeek == _filterDayOfWeek) {
      setState(() => _schedules.insert(0, created));
    }

    _showSnackBar('Schedule created successfully', isError: false);
  }

  Future<void> _openEditForm(DoctorScheduleModel schedule) async {
    final updated = await Navigator.of(context).push<DoctorScheduleModel>(
      MaterialPageRoute(
        builder: (_) => DoctorScheduleFormPage(existingSchedule: schedule),
      ),
    );

    if (updated == null || !mounted) return;

    setState(() {
      final index = _schedules.indexWhere((s) => s.id == updated.id);
      if (_filterDayOfWeek != null && updated.dayOfWeek != _filterDayOfWeek) {
        _schedules.removeWhere((s) => s.id == updated.id);
      } else if (index != -1) {
        _schedules[index] = updated;
      }
    });

    _showSnackBar('Schedule updated successfully', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }

  void _onDayFilterChanged(int? dayOfWeek) {
    setState(() => _filterDayOfWeek = dayOfWeek);
    _loadSchedules(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    // `doctor-schedule.viewAny` opens this page, but dentist and receptionist
    // stop there — they hold no `.create`/`.update`/`.delete`. Showing them the
    // buttons anyway sends them into a form whose branch picker 403s and whose
    // save would 403 too.
    final permissions = ref.watch(permissionServiceProvider);
    final canCreate = permissions.can(Perm.doctorScheduleCreate);
    final canUpdate = permissions.can(Perm.doctorScheduleUpdate);
    final canDelete = permissions.can(Perm.doctorScheduleDelete);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreateForm,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Schedule',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ─────────────────────────
            _buildHeader(),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Day Filter ──────────────────────────
            _buildDayFilterCard(),
            const SizedBox(height: AppDimensions.paddingMedium),

            // ── Body ────────────────────────────────
            Expanded(
              child: _buildBody(
                canCreate: canCreate,
                canUpdate: canUpdate,
                canDelete: canDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.textOnPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Doctor Schedules',
                  style: AppTextStyles.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage weekly availability for doctors',
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Refresh button
          _IconTile(
            tooltip: 'Refresh',
            icon: Icons.refresh_rounded,
            onTap: _refresh,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // DAY FILTER CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildDayFilterCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: DayFilterRow(
        selectedDay: _filterDayOfWeek,
        onChanged: _onDayFilterChanged,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BODY
  // ─────────────────────────────────────────────────────────
  Widget _buildBody({
    required bool canCreate,
    required bool canUpdate,
    required bool canDelete,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_schedules.isEmpty) {
      return _buildEmptyState(canCreate: canCreate);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _schedules.length + (_hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _schedules.length) {
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final schedule = _schedules[index];
          return Padding(
            padding:
                const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
            child: ScheduleCard(
              schedule: schedule,
              onEdit: canUpdate ? () => _openEditForm(schedule) : null,
              onDelete: canDelete ? () => _deleteSchedule(schedule) : null,
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // ERROR STATE
  // ─────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.paddingLarge),
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text('Something went wrong', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            FilledButton.icon(
              onPressed: _refresh,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingSmall,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────
  /// Read-only roles get no "add one" nudge — the button that would follow it
  /// isn't there for them.
  String _emptyStateHint({required bool canCreate}) {
    if (!canCreate) {
      return _filterDayOfWeek == null
          ? 'No doctor schedules have been set up yet'
          : 'No schedules on this day — try a different one';
    }

    return _filterDayOfWeek == null
        ? 'Start by adding a new doctor schedule'
        : 'Try a different day or add a schedule';
  }

  Widget _buildEmptyState({required bool canCreate}) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.paddingLarge),
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              _filterDayOfWeek == null
                  ? 'No schedules yet'
                  : 'No schedules for this day',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _emptyStateHint(canCreate: canCreate),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            if (canCreate) ...[
              const SizedBox(height: AppDimensions.paddingLarge),
              FilledButton.icon(
                onPressed: _openCreateForm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLarge,
                    vertical: AppDimensions.paddingSmall,
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Schedule'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// REUSABLE: Icon Tile Button
// ─────────────────────────────────────────────────────────
class _IconTile extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _IconTile({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
    );
  }
}