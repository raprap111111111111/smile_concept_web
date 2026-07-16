// lib/presentation/pages/appointments/widgets/booking_calendar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// How busy a day is, derived from the clinic-wide booking count.
///
/// Patients see the band rather than the raw number: it answers "will this day
/// be crowded?" — the reason they care — without turning the booking form into
/// a readout of clinic volume.
enum DayLoad {
  open,
  light,
  moderate,
  busy;

  static DayLoad fromCount(int count) {
    if (count <= 0) return DayLoad.open;
    if (count <= 3) return DayLoad.light;
    if (count <= 7) return DayLoad.moderate;
    return DayLoad.busy;
  }

  String get label => switch (this) {
        DayLoad.open => 'No bookings yet',
        DayLoad.light => 'Light',
        DayLoad.moderate => 'Moderate',
        DayLoad.busy => 'Busy',
      };

  Color get color => switch (this) {
        DayLoad.open => AppColors.textTertiary,
        DayLoad.light => AppColors.success,
        DayLoad.moderate => AppColors.warning,
        DayLoad.busy => AppColors.error,
      };

  /// Dots drawn under the day number. Open days get none — an empty day should
  /// read as calm, not as a fourth thing to decode.
  int get dots => switch (this) {
        DayLoad.open => 0,
        DayLoad.light => 1,
        DayLoad.moderate => 2,
        DayLoad.busy => 3,
      };
}

/// Month grid for picking an appointment date, showing how busy each day is.
///
/// [dayLoad] is keyed by 'yyyy-MM-dd'; a missing key means no bookings. The
/// parent owns fetching so the grid stays a pure render of what it is handed.
class BookingCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedDate;
  final Map<String, int> dayLoad;
  final bool isLoading;
  final DateTime firstSelectableDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;

  const BookingCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.dayLoad,
    required this.isLoading,
    required this.firstSelectableDate,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  static final _keyFormat = DateFormat('yyyy-MM-dd');

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _countFor(DateTime day) => dayLoad[_keyFormat.format(day)] ?? 0;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Months before the one holding [firstSelectableDate] contain no bookable
  /// day, so there is nothing to page back to.
  bool get _canGoBack {
    final floor = _dayOnly(firstSelectableDate);
    return month.year > floor.year ||
        (month.year == floor.year && month.month > floor.month);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      child: Column(
        children: [
          _buildMonthHeader(),
          const SizedBox(height: AppDimensions.paddingXS),
          _buildWeekdayLabels(),
          const SizedBox(height: 4),
          _buildDayGrid(),
          const SizedBox(height: AppDimensions.paddingXS),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.paddingXS),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _canGoBack
              ? () => onMonthChanged(DateTime(month.year, month.month - 1))
              : null,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textSecondary,
          disabledColor: AppColors.border,
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.ink),
              ),
              if (isLoading) ...[
                const SizedBox(width: AppDimensions.paddingXS),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right),
          color: AppColors.textSecondary,
          tooltip: 'Next month',
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDayGrid() {
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    // DateTime.weekday is 1=Mon..7=Sun, matching the Mon-first label row.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final cells = leadingBlanks + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _buildCell(
                    (row * 7 + col) - leadingBlanks + 1,
                    daysInMonth,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(int dayNumber, int daysInMonth) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 44);
    }

    final date = DateTime(month.year, month.month, dayNumber);
    final isPast = date.isBefore(_dayOnly(firstSelectableDate));
    final isSelected = selectedDate != null && _isSameDay(date, selectedDate!);
    final load = DayLoad.fromCount(_countFor(date));

    if (isPast) {
      return _DayCell(
        dayNumber: dayNumber,
        isSelected: false,
        isDisabled: true,
        load: DayLoad.open,
        onTap: null,
        semanticLabel: '${DateFormat('MMMM d').format(date)}, unavailable',
      );
    }

    return _DayCell(
      dayNumber: dayNumber,
      isSelected: isSelected,
      isDisabled: false,
      load: load,
      onTap: () => onDateSelected(date),
      semanticLabel:
          '${DateFormat('EEEE, MMMM d').format(date)}, ${load.label}',
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppDimensions.paddingSmall,
      runSpacing: 4,
      children: [
        for (final load in DayLoad.values)
          if (load != DayLoad.open)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: load.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  load.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int dayNumber;
  final bool isSelected;
  final bool isDisabled;
  final DayLoad load;
  final VoidCallback? onTap;
  final String semanticLabel;

  const _DayCell({
    required this.dayNumber,
    required this.isSelected,
    required this.isDisabled,
    required this.load,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    if (isSelected) {
      textColor = AppColors.textOnPrimary;
    } else if (isDisabled) {
      textColor = AppColors.textTertiary;
    } else {
      textColor = AppColors.ink;
    }

    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      button: !isDisabled,
      // The label already reads the date and how busy it is, so announce the
      // cell as one node instead of a bare day number plus loose dots.
      container: true,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          mouseCursor: isDisabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : null,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 5,
                  child: isDisabled
                      ? null
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < load.dots; i++)
                              Container(
                                width: 4,
                                height: 4,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  // On the selected (primary) fill, the load
                                  // colors lose contrast — go solid white.
                                  color: isSelected
                                      ? AppColors.textOnPrimary
                                      : load.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
