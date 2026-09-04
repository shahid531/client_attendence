import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/leave_request.dart';
import '../../repositories/leave_repository.dart';

class SubmitLeaveRequestUseCase
    implements UseCase<LeaveRequest, SubmitLeaveParams> {
  final LeaveRepository repository;

  SubmitLeaveRequestUseCase(this.repository);

  @override
  Future<Either<Failure, LeaveRequest>> call(SubmitLeaveParams params) async {
    return await repository.submitLeaveRequest(
      title: params.title,
      requestType: params.requestType,
      startDate: params.startDate,
      endDate: params.endDate,
      reason: params.reason,
    );
  }
}

class SubmitLeaveParams extends Equatable {
  final String title;
  final String requestType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  const SubmitLeaveParams({
    required this.title,
    required this.requestType,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  @override
  List<Object?> get props => [title, requestType, startDate, endDate, reason];
}
