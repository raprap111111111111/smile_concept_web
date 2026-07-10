class DashboardStats {
  final int appointmentsToday;
  final int newPatients;
  final int pendingReviews;
  final double monthlyRevenue;

  DashboardStats({
    required this.appointmentsToday,
    required this.newPatients,
    required this.pendingReviews,
    required this.monthlyRevenue,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      appointmentsToday: json['appointmentsToday'] ?? 0,
      newPatients: json['newPatients'] ?? 0,
      pendingReviews: json['pendingReviews'] ?? 0,
      monthlyRevenue: (json['monthlyRevenue'] ?? 0).toDouble(),
    );
  }
}