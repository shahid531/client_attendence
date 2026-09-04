import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodayAttendanceEvent extends AttendanceEvent {}

class LoadAttendanceHistoryEvent extends AttendanceEvent {}

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
