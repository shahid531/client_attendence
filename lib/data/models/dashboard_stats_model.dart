import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalHoursThisMonth,
    required super.daysPresent,
    required super.totalWorkingDays,
    required super.pendingRequests,
    required super.avgHoursPerDay,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalHoursThisMonth:
          (json['totalHoursThisMonth'] as num?)?.toDouble() ?? 168.0,
      daysPresent: (json['daysPresent'] as num?)?.toInt() ?? 21,
      totalWorkingDays: (json['totalWorkingDays'] as num?)?.toInt() ?? 22,
      pendingRequests: (json['pendingRequests'] as num?)?.toInt() ?? 2,
      avgHoursPerDay: (json['avgHoursPerDay'] as num?)?.toDouble() ?? 8.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalHoursThisMonth': totalHoursThisMonth,
      'daysPresent': daysPresent,
      'totalWorkingDays': totalWorkingDays,
      'pendingRequests': pendingRequests,
      'avgHoursPerDay': avgHoursPerDay,
    };
  }
}
