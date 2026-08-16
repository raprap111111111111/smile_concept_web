import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/activity_log/activity_logs_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import 'widgets/activity_log_card.dart';
import 'widgets/activity_log_detail_dialog.dart';
import 'widgets/activity_log_header.dart';
import 'widgets/activity_log_pagination.dart';
import 'widgets/activity_log_states.dart';
import 'widgets/activity_log_toolbar.dart';

class ActivityLogsPage extends ConsumerStatefulWidget {
  const ActivityLogsPage({super.key});

  @override
  ConsumerState<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends ConsumerState<ActivityLogsPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(activityLogsFilterProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(activityLogsFilterProvider);
    final logsAsync = ref.watch(filteredActivityLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActivityLogHeader(
            onRefresh: () => ref.invalidate(filteredActivityLogsProvider),
          ),
          ActivityLogToolbar(
            searchController: _searchCtrl,
            filterState: filterState,
            onSearchChanged: _onSearchChanged,
            onActionChanged: (v) =>
                ref.read(activityLogsFilterProvider.notifier).setAction(v),
            onSubjectChanged: (v) =>
                ref.read(activityLogsFilterProvider.notifier).setSubjectType(v),
            onReset: () {
              _searchCtrl.clear();
              ref.read(activityLogsFilterProvider.notifier).reset();
            },
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: logsAsync.when(
              loading: () => const ActivityLogLoadingState(),
              error: (e, _) => ActivityLogErrorState(
                error: e.toString(),
                onRetry: () => ref.invalidate(filteredActivityLogsProvider),
              ),
              data: (result) {
                if (result.records.isEmpty) {
                  return const ActivityLogEmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  itemCount: result.records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final log = result.records[i];
                    return ActivityLogCard(
                      log: log,
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => ActivityLogDetailDialog(log: log),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (logsAsync.hasValue)
            ActivityLogPagination(
              result: logsAsync.value!,
              onPageChanged: (page) =>
                  ref.read(activityLogsFilterProvider.notifier).setPage(page),
            ),
        ],
      ),
    );
  }
}