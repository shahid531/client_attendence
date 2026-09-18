import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodayAttendanceEvent extends AttendanceEvent {}

class LoadAttendanceHistoryEvent extends AttendanceEvent {
  final String? startDate;
  final String? endDate;
  final String? filter;
  final int page;
  final int size;
  final String? employeeId;
  final String? employeeName;
  final bool isLoadMore;

  const LoadAttendanceHistoryEvent({
    this.startDate,
    this.endDate,
    this.filter,
    this.page = 0,
    this.size = 10,
    this.employeeId,
    this.employeeName,
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [startDate, endDate, filter, page, size, employeeId, employeeName, isLoadMore];
}

class CheckInRequestedEvent extends AttendanceEvent {
  final String workType;
  final String location;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? deviceId;

  const CheckInRequestedEvent({
    required this.workType,
    required this.location,
    required this.description,
    this.latitude,
    this.longitude,
    this.deviceId,
  });

  @override
  List<Object?> get props => [workType, location, description, latitude, longitude, deviceId];
}

class CheckOutRequestedEvent extends AttendanceEvent {
  final String recordId;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? deviceId;

  const CheckOutRequestedEvent({
    required this.recordId,
    required this.description,
    this.latitude,
    this.longitude,
    this.deviceId,
  });

  @override
  List<Object?> get props => [recordId, description, latitude, longitude, deviceId];
}

class ResetAttendanceEvent extends AttendanceEvent {}

class RegularizeAttendanceRequestedEvent extends AttendanceEvent {
  final String attendanceId;
  final String requestedTimeOut;
  final String reason;

  const RegularizeAttendanceRequestedEvent({
    required this.attendanceId,
    required this.requestedTimeOut,
    required this.reason,
  });

  @override
  List<Object?> get props => [attendanceId, requestedTimeOut, reason];
}

enum ExportAction { download, share }

class ExportAttendanceEvent extends AttendanceEvent {
  final String? employeeId;
  final String? fromDate;
  final String? toDate;
  final String dateRange;
  final ExportAction action;

  const ExportAttendanceEvent({
    this.employeeId,
    this.fromDate,
    this.toDate,
    required this.dateRange,
    required this.action,
  });

  @override
  List<Object?> get props => [employeeId, fromDate, toDate, dateRange, action];
}
