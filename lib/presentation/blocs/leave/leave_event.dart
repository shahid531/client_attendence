import 'package:equatable/equatable.dart';

abstract class LeaveEvent extends Equatable {
  const LeaveEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeaveRequestsEvent extends LeaveEvent {}

class SubmitLeaveRequestEvent extends LeaveEvent {
  final String title;
  final String requestType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  const SubmitLeaveRequestEvent({
    required this.title,
    required this.requestType,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  @override
  List<Object?> get props => [title, requestType, startDate, endDate, reason];
}

class UpdateRequestStatusEvent extends LeaveEvent {
  final String requestId;
  final String status;
  final String? remarks;

  const UpdateRequestStatusEvent({
    required this.requestId,
    required this.status,
    this.remarks,
  });

  @override
  List<Object?> get props => [requestId, status, remarks];
}
