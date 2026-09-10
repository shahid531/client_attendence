import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/leave_request.dart';
import '../../repositories/leave_repository.dart';

class GetLeaveRequestsParams extends Equatable {
  final String? status;
  final int page;
  final int pageSize;
  final String? employeeId;
  final String? employeeName;

  const GetLeaveRequestsParams({
    this.status,
    this.page = 0,
    this.pageSize = 10,
    this.employeeId,
    this.employeeName,
  });

  @override
  List<Object?> get props => [status, page, pageSize, employeeId, employeeName];
}

class GetLeaveRequestsUseCase implements UseCase<LeaveRequestsResult, GetLeaveRequestsParams> {
  final LeaveRepository repository;

  GetLeaveRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, LeaveRequestsResult>> call(GetLeaveRequestsParams params) async {
    return await repository.getLeaveRequests(
      status: params.status,
      page: params.page,
      pageSize: params.pageSize,
      employeeId: params.employeeId,
      employeeName: params.employeeName,
    );
  }
}

