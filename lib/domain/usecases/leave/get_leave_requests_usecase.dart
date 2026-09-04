import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/leave_request.dart';
import '../../repositories/leave_repository.dart';

class GetLeaveRequestsParams extends Equatable {
  final String? status;

  const GetLeaveRequestsParams({this.status});

  @override
  List<Object?> get props => [status];
}

class GetLeaveRequestsUseCase implements UseCase<List<LeaveRequest>, GetLeaveRequestsParams> {
  final LeaveRepository repository;

  GetLeaveRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<LeaveRequest>>> call(GetLeaveRequestsParams params) async {
    return await repository.getLeaveRequests(status: params.status);
  }
}

