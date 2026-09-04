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

  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceHistory();
  Future<Either<Failure, AttendanceRecord?>> getTodayAttendance();
}
