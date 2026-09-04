import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_remote_datasource.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDataSource remoteDataSource;

  LeaveRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, LeaveRequest>> submitLeaveRequest({
    required String title,
    required String requestType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      final request = await remoteDataSource.submitLeaveRequest(
        title: title,
        requestType: requestType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      return Right(request);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LeaveRequest>>> getLeaveRequests() async {
    try {
      final requests = await remoteDataSource.getLeaveRequests();
      return Right(requests);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRequestStatus({
    required String requestId,
    required String status,
    String? remarks,
  }) async {
    try {
      await remoteDataSource.updateRequestStatus(
        requestId: requestId,
        status: status,
        remarks: remarks,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
