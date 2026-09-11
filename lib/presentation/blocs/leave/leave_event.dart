import 'package:equatable/equatable.dart';

abstract class LeaveEvent extends Equatable {
  const LeaveEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeaveRequestsEvent extends LeaveEvent {
  final String? status;
  final int page;
  final int pageSize;
  final String? employeeId;
  final String? employeeName;
  final bool isLoadMore;
  final bool isApprovals;

  const LoadLeaveRequestsEvent({
    this.status,
    this.page = 0,
    this.pageSize = 10,
    this.employeeId,
    this.employeeName,
    this.isLoadMore = false,
    this.isApprovals = false,
  });

  @override
  List<Object?> get props => [status, page, pageSize, employeeId, employeeName, isLoadMore, isApprovals];
}


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
  final bool isApprovals;

  const UpdateRequestStatusEvent({
    required this.requestId,
    required this.status,
    this.remarks,
    this.isApprovals = true,
  });

  @override
  List<Object?> get props => [requestId, status, remarks, isApprovals];
}
