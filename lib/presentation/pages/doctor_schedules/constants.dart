// lib/presentation/pages/doctor_schedules/constants.dart

const List<Map<String, dynamic>> kDaysOfWeek = [
  {'value': 0, 'label': 'Sunday'},
  {'value': 1, 'label': 'Monday'},
  {'value': 2, 'label': 'Tuesday'},
  {'value': 3, 'label': 'Wednesday'},
  {'value': 4, 'label': 'Thursday'},
  {'value': 5, 'label': 'Friday'},
  {'value': 6, 'label': 'Saturday'},
];

String dayLabelOf(int value) =>
    kDaysOfWeek.firstWhere(
      (d) => d['value'] == value,
      orElse: () => {'label': 'Unknown'},
    )['label'] as String;