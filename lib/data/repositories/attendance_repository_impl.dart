import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AttendanceRecord>> checkIn({
    required String workType,
    required String location,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  }) async {
    try {
      final record = await remoteDataSource.checkIn(
        workType: workType,
        location: location,
        description: description,
        latitude: latitude,
        longitude: longitude,
        deviceId: deviceId,
      );
      return Right(record);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AttendanceRecord>> checkOut({
    required String recordId,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  }) async {
    try {
      final record = await remoteDataSource.checkOut(
        recordId: recordId,
        description: description,
        latitude: latitude,
        longitude: longitude,
        deviceId: deviceId,
      );
      return Right(record);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    String? filter,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final records = await remoteDataSource.getAttendanceHistory(
        startDate: startDate,
        endDate: endDate,
        filter: filter,
        page: page,
        size: size,
      );
      return Right(records);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AttendanceRecord?>> getTodayAttendance() async {
    try {
      final record = await remoteDataSource.getTodayAttendance();
      return Right(record);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
