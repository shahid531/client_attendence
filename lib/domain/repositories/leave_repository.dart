import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/leave_request.dart';

abstract class LeaveRepository {
  Future<Either<Failure, LeaveRequest>> submitLeaveRequest({
    required String title,
    required String requestType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  });

  Future<Either<Failure, List<LeaveRequest>>> getLeaveRequests();
  Future<Either<Failure, void>> updateRequestStatus({
    required String requestId,
    required String status,
    String? remarks,
  });
}
