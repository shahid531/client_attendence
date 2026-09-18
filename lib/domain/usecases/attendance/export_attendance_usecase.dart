import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/attendance_repository.dart';

class ExportAttendanceParams extends Equatable {
  final String? employeeId;
  final String? fromDate;
  final String? toDate;

  const ExportAttendanceParams({
    this.employeeId,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [employeeId, fromDate, toDate];
}

class ExportAttendanceUseCase
    implements UseCase<List<int>, ExportAttendanceParams> {
  final AttendanceRepository repository;

  ExportAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, List<int>>> call(
      ExportAttendanceParams params) async {
    return await repository.exportAttendance(
      employeeId: params.employeeId,
      fromDate: params.fromDate,
      toDate: params.toDate,
    );
  }
}
