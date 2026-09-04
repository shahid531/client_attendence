import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/leave_request.dart';
import '../../repositories/leave_repository.dart';

class GetLeaveRequestsUseCase implements UseCase<List<LeaveRequest>, NoParams> {
  final LeaveRepository repository;

  GetLeaveRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<LeaveRequest>>> call(NoParams params) async {
    return await repository.getLeaveRequests();
  }
}
