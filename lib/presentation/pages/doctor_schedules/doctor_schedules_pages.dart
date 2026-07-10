// lib/presentation/pages/doctor_schedules/doctor_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/doctor_schedule/doctor_schedule_model.dart';
import '../../../data/repositories/doctor_schedule_repository.dart';
import '../../providers/doctor_schedule/doctor_schedule_provider.dart';
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
  ConsumerState<DoctorSchedulePage> createState() =>
      _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends ConsumerState<DoctorSchedulePage> {
  final ScrollController _scrollController = ScrollController();

  List<DoctorScheduleModel> _schedules = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  bool _hasNextPage = false;

  /// null = All Days
  /// 0 = Sunday
  /// 1 = Monday
  /// 2 = Tuesday
  /// ...
  /// 6 = Saturday
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

      // Safety filter:
      // If backend ignores day_of_week, frontend still filters correctly.
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

    setState(() {
      _currentPage++;
    });

    await _loadSchedules(reset: false);
  }

  Future<void> _refresh() async {
    await _loadSchedules(reset: true);
  }

  Future<void> _deleteSchedule(DoctorScheduleModel schedule) async {
    final confirmed = await _showDeleteDialog(schedule);
    if (!confirmed) return;

    try {
      await _repository.deleteSchedule(schedule.id);

      if (!mounted) return;

      setState(() {
        _schedules.removeWhere((s) => s.id == schedule.id);
      });

      _showSnackBar('Schedule deleted successfully.', isError: false);
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

    // If current filter matches created schedule, add it.
    if (_filterDayOfWeek == null || created.dayOfWeek == _filterDayOfWeek) {
      setState(() {
        _schedules.insert(0, created);
      });
    }

    _showSnackBar('Schedule created successfully.', isError: false);
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

      // If updated schedule no longer matches selected day, remove it.
      if (_filterDayOfWeek != null &&
          updated.dayOfWeek != _filterDayOfWeek) {
        _schedules.removeWhere((s) => s.id == updated.id);
      } else if (index != -1) {
        _schedules[index] = updated;
      }
    });

    _showSnackBar('Schedule updated successfully.', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showDeleteDialog(DoctorScheduleModel schedule) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Schedule'),
            content: Text(
              'Delete ${schedule.dayLabel} schedule for '
              '${schedule.doctor?.profile.name ?? "this doctor"}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _onDayFilterChanged(int? dayOfWeek) {
    setState(() {
      _filterDayOfWeek = dayOfWeek;
    });

    _loadSchedules(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Schedules'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Schedule'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          DayFilterRow(
            selectedDay: _filterDayOfWeek,
            onChanged: _onDayFilterChanged,
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_schedules.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _schedules.length + (_hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _schedules.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final schedule = _schedules[index];

          return ScheduleCard(
            schedule: schedule,
            onEdit: () => _openEditForm(schedule),
            onDelete: () => _deleteSchedule(schedule),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _filterDayOfWeek == null
                ? 'No schedules found.'
                : 'No schedules found for this day.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _openCreateForm,
            icon: const Icon(Icons.add),
            label: const Text('Add Schedule'),
          ),
        ],
      ),
    );
  }
}