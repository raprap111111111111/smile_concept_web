// lib/data/models/lab_case/lab_case_constants.dart

class LabCaseStatus {
  static const String sent = 'sent';
  static const String inProgress = 'in_progress';
  static const String received = 'received';
  static const String fitted = 'fitted';
  static const String rejected = 'rejected';

  static const List<String> all = [
    sent,
    inProgress,
    received,
    fitted,
    rejected,
  ];

  static String label(String status) {
    return switch (status) {
      'sent' => 'Sent',
      'in_progress' => 'In Progress',
      'received' => 'Received',
      'fitted' => 'Fitted',
      'rejected' => 'Rejected',
      _ => status,
    };
  }
}

class LabWorkType {
  static const String crown = 'Crown';
  static const String bridge = 'Bridge';
  static const String denture = 'Denture';
  static const String veneer = 'Veneer';
  static const String aligners = 'Aligners';
  static const String implantCrown = 'Implant Crown';
  static const String nightGuard = 'Night Guard';
  static const String retainer = 'Retainer';
  static const String other = 'Other';

  static const List<String> all = [
    crown,
    bridge,
    denture,
    veneer,
    aligners,
    implantCrown,
    nightGuard,
    retainer,
    other,
  ];
}