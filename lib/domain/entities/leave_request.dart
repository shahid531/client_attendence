import 'package:equatable/equatable.dart';

class LeaveRequest extends Equatable {
  final String id;
  final String title;
  final String requestType; // 'Leave', 'Attendance Adjustment'
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final DateTime submittedAt;

  const LeaveRequest({
    required this.id,
    required this.title,
    required this.requestType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.submittedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        requestType,
        startDate,
        endDate,
        reason,
        status,
        submittedAt,
      ];
}
