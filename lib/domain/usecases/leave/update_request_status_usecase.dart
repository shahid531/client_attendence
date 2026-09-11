import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/leave_repository.dart';

class UpdateRequestStatusUseCase implements UseCase<String, UpdateRequestStatusParams> {
  final LeaveRepository repository;

  UpdateRequestStatusUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(UpdateRequestStatusParams params) async {
    return await repository.updateRequestStatus(
      requestId: params.requestId,
      status: params.status,
      remarks: params.remarks,
    );
  }
}

class UpdateRequestStatusParams extends Equatable {
  final String requestId;
  final String status;
  final String? remarks;

  const UpdateRequestStatusParams({
    required this.requestId,
    required this.status,
    this.remarks,
  });

  @override
  List<Object?> get props => [requestId, status, remarks];
}
