import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/attendance_repository.dart';

class CheckOutUseCase implements UseCase<AttendanceRecord, CheckOutParams> {
  final AttendanceRepository repository;

  CheckOutUseCase(this.repository);

  @override
  Future<Either<Failure, AttendanceRecord>> call(CheckOutParams params) async {
    return await repository.checkOut(
      recordId: params.recordId,
      description: params.description,
    );
  }
}

class CheckOutParams extends Equatable {
  final String recordId;
  final String description;

  const CheckOutParams({
    required this.recordId,
    required this.description,
  });

  @override
  List<Object?> get props => [recordId, description];
}
