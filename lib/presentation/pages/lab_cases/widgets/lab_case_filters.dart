// lib/presentation/pages/lab_cases/widgets/lab_case_filters.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/theme/app_dimensions.dart';
import 'package:smile_concept_web/presentation/theme/app_text_styles.dart';
import 'package:smile_concept_web/presentation/providers/lab_case/lab_case_provider.dart';

class LabCaseFilters extends ConsumerStatefulWidget {
  const LabCaseFilters({super.key});

  @override
  ConsumerState<LabCaseFilters> createState() => _LabCaseFiltersState();
}

class _LabCaseFiltersState extends ConsumerState<LabCaseFilters> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    final query = _searchController.text.trim();
    ref
        .read(labCaseProvider.notifier)
        .setSearch(query.isEmpty ? null : query);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _runSearch(),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by lab name, work type, patient...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(labCaseProvider.notifier)
                              .setSearch(null);
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: AppDimensions.paddingMedium),

        // Search button
        FilledButton.icon(
          onPressed: _runSearch,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Search'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
            ),
          ),
        ),
      ],
    );
  }
}