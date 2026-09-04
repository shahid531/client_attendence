import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/attendance_repository.dart';

class GetAttendanceHistoryUseCase
    implements UseCase<List<AttendanceRecord>, NoParams> {
  final AttendanceRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<AttendanceRecord>>> call(NoParams params) async {
    return await repository.getAttendanceHistory();
  }
}
