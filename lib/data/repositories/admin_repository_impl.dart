import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
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
  Future<Either<Failure, List<ClientLocation>>> getLocations({
    String? clientName,
    String? city,
  }) async {
    try {
      final result = await remoteDataSource.getLocations(
        clientName: clientName,
        city: city,
      );
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
    String? city,
    required double latitude,
    required double longitude,
    required double allowedRadius,
  }) async {
    try {
      final result = await remoteDataSource.createLocation(
        clientName: clientName,
        locationName: locationName,
        address: address,
        city: city,
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

  @override
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
  }) async {
    try {
      final result = await remoteDataSource.updateLocation(
        id: id,
        clientName: clientName,
        locationName: locationName,
        address: address,
        city: city,
        latitude: latitude,
        longitude: longitude,
        allowedRadius: allowedRadius,
        halfDayHrs: halfDayHrs,
        fullDayHrs: fullDayHrs,
        status: status,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> downloadBulkUploadSample() async {
    try {
      final bytes = await remoteDataSource.downloadBulkUploadSample();

      Directory? targetDir;
      if (Platform.isAndroid) {
        final androidDownload = Directory('/storage/emulated/0/Download');
        if (await androidDownload.exists()) {
          targetDir = androidDownload;
        } else {
          targetDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        targetDir = await getApplicationDocumentsDirectory();
      } else {
        targetDir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }
      targetDir ??= await getApplicationDocumentsDirectory();

      final filePath = '${targetDir.path}/employees_sample_template.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return Right(filePath);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> bulkUploadEmployees({
    required String filePath,
    required String fileName,
    List<int>? fileBytes,
  }) async {
    try {
      final result = await remoteDataSource.bulkUploadEmployees(
        filePath: filePath,
        fileName: fileName,
        fileBytes: fileBytes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

