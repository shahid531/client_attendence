import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/attendance_repository.dart';

class RegularizeAttendanceParams extends Equatable {
  final String attendanceId;
  final String requestedTimeOut;
  final String reason;

  const RegularizeAttendanceParams({
    required this.attendanceId,
    required this.requestedTimeOut,
    required this.reason,
  });

  @override
  List<Object?> get props => [attendanceId, requestedTimeOut, reason];
}

class RegularizeAttendanceUseCase implements UseCase<void, RegularizeAttendanceParams> {
  final AttendanceRepository repository;

  RegularizeAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RegularizeAttendanceParams params) async {
    return await repository.regularizeAttendance(
      attendanceId: params.attendanceId,
      requestedTimeOut: params.requestedTimeOut,
      reason: params.reason,
    );
  }
}
