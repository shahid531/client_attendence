import 'package:equatable/equatable.dart';
import '../../../domain/entities/leave_request.dart';

abstract class LeaveState extends Equatable {
  const LeaveState();

  @override
  List<Object?> get props => [];
}

class LeaveInitialState extends LeaveState {}

class LeaveLoadingState extends LeaveState {}

class LeaveLoadedState extends LeaveState {
  final List<LeaveRequest> requests;
  final String? successMessage;

  const LeaveLoadedState({
    required this.requests,
    this.successMessage,
  });

  @override
  List<Object?> get props => [requests, successMessage];
}

class LeaveErrorState extends LeaveState {
  final String message;

  const LeaveErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
