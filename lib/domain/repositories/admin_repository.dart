import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/client_location.dart';
import '../entities/created_employee.dart';

abstract class AdminRepository {
  Future<Either<Failure, CreatedEmployee>> createEmployee({
    required String email,
    required String employeeId,
    required String fullName,
    required String locationId,
    String? locationName,
    double? latitude,
    double? longitude,
    required String role,
    required String contactNumber,
    String? reportingManagerEmployeeId,
  });

  Future<Either<Failure, List<CreatedEmployee>>> getEmployees();

  Future<Either<Failure, List<ClientLocation>>> getLocations();

  Future<Either<Failure, ClientLocation>> createLocation({
    required String clientName,
    required String locationName,
    required String address,
    String? city,
    required double latitude,
    required double longitude,
    required double allowedRadius,
  });
}

