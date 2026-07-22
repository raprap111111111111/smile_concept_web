// lib/presentation/pages/dashboard/components/charts/status_breakdown_bar.dart
import 'package:flutter/material.dart';

import '../../../../../data/models/dashboard/chart_series.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/chart_palette.dart';

/// Part-to-whole split of today's appointments by status, as a single
/// horizontal stacked bar plus a labelled legend.
///
/// Segments are separated by a 2px gap in the surface colour rather than a
/// stroke, and stack in [ChartPalette.statusOrder] — the order the palette was
/// validated in. Every slot is named in the legend with an icon beside it, so
/// status never travels as colour alone (and the sub-3:1 pending amber has its
/// required relief channel).
class StatusBreakdownBar extends StatelessWidget {
  const StatusBreakdownBar({super.key, required this.statuses});

  final List<CategoryCount> statuses;

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered();
    final total = ordered.fold<int>(0, (sum, s) => sum + s.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
          child: total == 0
              ? Container(
                  decoration: BoxDecoration(
                    color: ChartPalette.gridline,
                    borderRadius: BorderRadius.circular(5),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Row(
                    children: [
                      for (final entry in ordered.where((s) => s.count > 0))
                        ..._segmentWithGap(entry, ordered),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final entry in ordered)
              _LegendItem(
                label: entry.label.isEmpty ? entry.key : entry.label,
                count: entry.count,
                color: ChartPalette.forStatus(entry.key),
                icon: ChartPalette.iconForStatus(entry.key),
              ),
          ],
        ),
      ],
    );
  }

  /// Sorts into the validated stacking order, keeping any unknown status last.
  List<CategoryCount> _ordered() {
    final sorted = [...statuses];
    sorted.sort((a, b) {
      final ai = ChartPalette.statusOrder.indexOf(a.key.toLowerCase());
      final bi = ChartPalette.statusOrder.indexOf(b.key.toLowerCase());
      return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
    });
    return sorted;
  }

  List<Widget> _segmentWithGap(
    CategoryCount entry,
    List<CategoryCount> ordered,
  ) {
    final visible = ordered.where((s) => s.count > 0).toList();
    final isLast = identical(visible.last, entry);

    return [
      Expanded(
        flex: entry.count,
        child: Container(color: ChartPalette.forStatus(entry.key)),
      ),
      // Surface-coloured gap does the separating; never a border on the mark.
      if (!isLast) Container(width: 2, color: ChartPalette.surface),
    ];
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          // Text wears text tokens; the icon beside it carries identity.
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
