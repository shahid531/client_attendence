import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, AttendanceRecord>> checkIn({
    required String workType,
    required String location,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  });

  Future<Either<Failure, AttendanceRecord>> checkOut({
    required String recordId,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  });

  Future<Either<Failure, AttendanceHistoryResult>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    String? filter,
    int page = 0,
    int size = 10,
    String? employeeId,
    String? employeeName,
  });
  Future<Either<Failure, AttendanceRecord?>> getTodayAttendance();
}

