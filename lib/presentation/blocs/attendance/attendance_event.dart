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

  const LoadAttendanceHistoryEvent({
    this.startDate,
    this.endDate,
    this.filter,
    this.page = 0,
    this.size = 20,
  });

  @override
  List<Object?> get props => [startDate, endDate, filter, page, size];
}

class CheckInRequestedEvent extends AttendanceEvent {
  final String workType;
  final String location;
  final String description;

  const CheckInRequestedEvent({
    required this.workType,
    required this.location,
    required this.description,
  });

  @override
  List<Object?> get props => [workType, location, description];
}

class CheckOutRequestedEvent extends AttendanceEvent {
  final String recordId;
  final String description;

  const CheckOutRequestedEvent({
    required this.recordId,
    required this.description,
  });

  @override
  List<Object?> get props => [recordId, description];
}

class ResetAttendanceEvent extends AttendanceEvent {}
