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

  Future<Either<Failure, CreatedEmployee>> updateEmployee({
    required int id,
    required String fullName,
    required String email,
    required String contactNumber,
    required String role,
    String? status,
    required String locationId,
    String? reportingManagerEmployeeId,
  });

  Future<Either<Failure, List<CreatedEmployee>>> getEmployees({
    String? name,
    String? reportingManagerId,
  });

  Future<Either<Failure, List<ClientLocation>>> getLocations({
    String? clientName,
    String? city,
  });

  Future<Either<Failure, ClientLocation>> createLocation({
    required String clientName,
    required String locationName,
    required String address,
    String? city,
    required double latitude,
    required double longitude,
    required double allowedRadius,
  });

  Future<Either<Failure, ClientLocation>> updateLocation({
    required dynamic id,
    required String clientName,
    required String locationName,
    required String address,
    String? city,
    required double latitude,
    required double longitude,
    required double allowedRadius,
    double? halfDayHrs,
    double? fullDayHrs,
    String? status,
  });

  Future<Either<Failure, String>> downloadBulkUploadSample();

  Future<Either<Failure, Map<String, dynamic>>> bulkUploadEmployees({
    required String filePath,
    required String fileName,
    List<int>? fileBytes,
  });
}

