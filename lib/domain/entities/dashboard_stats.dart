import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final double totalHoursThisMonth;
  final int daysPresent;
  final int totalWorkingDays;
  final int pendingRequests;
  final double avgHoursPerDay;

  const DashboardStats({
    required this.totalHoursThisMonth,
    required this.daysPresent,
    required this.totalWorkingDays,
    required this.pendingRequests,
    required this.avgHoursPerDay,
  });

  @override
  List<Object?> get props => [
        totalHoursThisMonth,
        daysPresent,
        totalWorkingDays,
        pendingRequests,
        avgHoursPerDay,
      ];
}
