import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/attendance_repository.dart';

class CheckInUseCase implements UseCase<AttendanceRecord, CheckInParams> {
  final AttendanceRepository repository;

  CheckInUseCase(this.repository);

  @override
  Future<Either<Failure, AttendanceRecord>> call(CheckInParams params) async {
    return await repository.checkIn(
      workType: params.workType,
      location: params.location,
      description: params.description,
    );
  }
}

class CheckInParams extends Equatable {
  final String workType;
  final String location;
  final String description;

  const CheckInParams({
    required this.workType,
    required this.location,
    required this.description,
  });

  @override
  List<Object?> get props => [workType, location, description];
}
