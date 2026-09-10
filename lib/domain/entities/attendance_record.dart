import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  final String id;
  final DateTime date;
  final String checkInTime;
  final String? checkOutTime;
  final String workType; // 'GPS' or 'WFH'
  final String location;
  final String description;
  final double totalHours;
  final String status; // 'Present', 'Half Day', 'On Leave'
  final String? employeeId;
  final String? employeeName;
  final String? timeInDescription;
  final String? timeOutDescription;
  final String? requestStatus;
  final String? requestId;

  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    required this.workType,
    required this.location,
    required this.description,
    required this.totalHours,
    required this.status,
    this.employeeId,
    this.employeeName,
    this.timeInDescription,
    this.timeOutDescription,
    this.requestStatus,
    this.requestId,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        checkInTime,
        checkOutTime,
        workType,
        location,
        description,
        totalHours,
        status,
        employeeId,
        employeeName,
        timeInDescription,
        timeOutDescription,
        requestStatus,
        requestId,
      ];
}

class AttendanceHistoryResult extends Equatable {
  final List<AttendanceRecord> records;
  final int page;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const AttendanceHistoryResult({
    required this.records,
    this.page = 0,
    this.pageSize = 10,
    this.totalElements = 0,
    this.totalPages = 1,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  @override
  List<Object?> get props => [
        records,
        page,
        pageSize,
        totalElements,
        totalPages,
        hasNext,
        hasPrevious,
      ];
}
