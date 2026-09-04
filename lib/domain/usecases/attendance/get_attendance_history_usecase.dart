import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/attendance_record.dart';
import '../../repositories/attendance_repository.dart';

class GetAttendanceHistoryParams extends Equatable {
  final String? startDate;
  final String? endDate;
  final String? filter;
  final int page;
  final int size;

  const GetAttendanceHistoryParams({
    this.startDate,
    this.endDate,
    this.filter,
    this.page = 0,
    this.size = 20,
  });

  @override
  List<Object?> get props => [startDate, endDate, filter, page, size];
}

class GetAttendanceHistoryUseCase
    implements UseCase<List<AttendanceRecord>, GetAttendanceHistoryParams> {
  final AttendanceRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<AttendanceRecord>>> call(
      GetAttendanceHistoryParams params) async {
    return await repository.getAttendanceHistory(
      startDate: params.startDate,
      endDate: params.endDate,
      filter: params.filter,
      page: params.page,
      size: params.size,
    );
  }
}

