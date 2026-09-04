import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, AttendanceRecord>> checkIn({
    required String workType,
    required String location,
    required String description,
  });

  Future<Either<Failure, AttendanceRecord>> checkOut({
    required String recordId,
    required String description,
  });

  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    String? filter,
    int page = 0,
    int size = 20,
  });
  Future<Either<Failure, AttendanceRecord?>> getTodayAttendance();
}

