import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/attendance_repository.dart';

class GetTodayAttendanceUseCase
    implements UseCase<AttendanceRecord?, NoParams> {
  final AttendanceRepository repository;

  GetTodayAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, AttendanceRecord?>> call(NoParams params) async {
    return await repository.getTodayAttendance();
  }
}
