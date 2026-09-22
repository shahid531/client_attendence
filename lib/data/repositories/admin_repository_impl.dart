import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/client_location.dart';
import '../../domain/entities/created_employee.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
    try {
      final result = await remoteDataSource.createEmployee(
        email: email,
        employeeId: employeeId,
        fullName: fullName,
        locationId: locationId,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        role: role,
        contactNumber: contactNumber,
        reportingManagerEmployeeId: reportingManagerEmployeeId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CreatedEmployee>>> getEmployees({String? name}) async {
    try {
      final result = await remoteDataSource.getEmployees(name: name);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ClientLocation>>> getLocations() async {
    try {
      final result = await remoteDataSource.getLocations();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ClientLocation>> createLocation({
    required String clientName,
    required String locationName,
    required String address,
    required double latitude,
    required double longitude,
    required double allowedRadius,
  }) async {
    try {
      final result = await remoteDataSource.createLocation(
        clientName: clientName,
        locationName: locationName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        allowedRadius: allowedRadius,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

