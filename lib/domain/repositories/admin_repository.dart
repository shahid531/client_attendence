import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/created_employee.dart';

abstract class AdminRepository {
  Future<Either<Failure, CreatedEmployee>> createEmployee({
    required String email,
    required String employeeId,
    required String fullName,
    required String locationId,
    required String role,
    required String contactNumber,
    String? reportingManagerEmployeeId,
  });
}
