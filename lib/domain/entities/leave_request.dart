import 'package:equatable/equatable.dart';

class LeaveRequest extends Equatable {
  final String id;
  final String requestId;
  final String employeeId;
  final String employeeName;
  final String attendanceId;
  final String title;
  final String requestType; // 'Leave', 'WFH', 'Attendance Adjustment'
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED' / 'Pending'
  final DateTime submittedAt;
  final String? requestedTimeOut;
  final String? assignedApproverName;
  final String? timeIn;
  final String? timeOut;

  const LeaveRequest({
    required this.id,
    this.requestId = '',
    this.employeeId = '',
    this.employeeName = '',
    this.attendanceId = '',
    required this.title,
    required this.requestType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.submittedAt,
    this.requestedTimeOut,
    this.assignedApproverName,
    this.timeIn,
    this.timeOut,
  });

  @override
  List<Object?> get props => [
        id,
        requestId,
        employeeId,
        employeeName,
        attendanceId,
        title,
        requestType,
        startDate,
        endDate,
        reason,
        status,
        submittedAt,
        requestedTimeOut,
        assignedApproverName,
    timeIn,
    timeOut
      ];
}

class LeaveRequestsResult extends Equatable {
  final List<LeaveRequest> requests;
  final int page;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final int? pendingCount;
  final int? completedCount;

  const LeaveRequestsResult({
    required this.requests,
    this.page = 0,
    this.pageSize = 10,
    this.totalElements = 0,
    this.totalPages = 1,
    this.hasNext = false,
    this.hasPrevious = false,
    this.pendingCount,
    this.completedCount,
  });

  @override
  List<Object?> get props => [
        requests,
        page,
        pageSize,
        totalElements,
        totalPages,
        hasNext,
        hasPrevious,
        pendingCount,
        completedCount,
      ];
}

