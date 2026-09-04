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
  }) async {
    try {
      final record = await remoteDataSource.checkIn(
        workType: workType,
        location: location,
        description: description,
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
  }) async {
    try {
      final record = await remoteDataSource.checkOut(
        recordId: recordId,
        description: description,
      );
      return Right(record);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceHistory() async {
    try {
      final records = await remoteDataSource.getAttendanceHistory();
      return Right(records);
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
