import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/error_handler.dart';
import '../../core/errors/exceptions.dart';
import '../models/client_location_model.dart';
import '../models/created_employee_model.dart';

abstract class AdminRemoteDataSource {
  Future<CreatedEmployeeModel> createEmployee({
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

  Future<List<CreatedEmployeeModel>> getEmployees({String? name});

  Future<List<ClientLocationModel>> getLocations({
    String? clientName,
    String? city,
  });

  Future<ClientLocationModel> createLocation({
    required String clientName,
    required String locationName,
    required String address,
    String? city,
    required double latitude,
    required double longitude,
    required double allowedRadius,
  });

  Future<List<int>> downloadBulkUploadSample();

  Future<Map<String, dynamic>> bulkUploadEmployees({
    required String filePath,
    required String fileName,
    List<int>? fileBytes,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;
  final SharedPreferences sharedPreferences;

  AdminRemoteDataSourceImpl({
    required this.dio,
    required this.sharedPreferences,
  });

  @override
  Future<List<ClientLocationModel>> getLocations({
    String? clientName,
    String? city,
  }) async {
    try {
      final cachedToken = sharedPreferences.getString('auth_bearer_token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'ngrok-skip-browser-warning': 'true',
      };
      if (cachedToken != null && cachedToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $cachedToken';
      }

      final queryParams = <String, dynamic>{};
      if (clientName != null && clientName.trim().isNotEmpty) {
        queryParams['clientName'] = clientName.trim();
      }
      if (city != null && city.trim().isNotEmpty) {
        queryParams['city'] = city.trim();
      }

      final response = await dio.get(
        ApiConstants.adminLocations,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw ServerException(data['message'] ?? 'Failed to fetch locations');
        }

        final rawList = data['data'];
        if (rawList is List) {
          return rawList
              .whereType<Map<String, dynamic>>()
              .map((e) => ClientLocationModel.fromJson(e))
              .toList();
        }
        return <ClientLocationModel>[];
      }

      throw const ServerException('Invalid response format from server');
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e, fallbackMessage: 'Failed to fetch locations. Please try again.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CreatedEmployeeModel>> getEmployees({String? name}) async {
    try {
      final cachedToken = sharedPreferences.getString('auth_bearer_token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'ngrok-skip-browser-warning': 'true',
      };
      if (cachedToken != null && cachedToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $cachedToken';
      }

      final queryParams = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        queryParams['name'] = name.trim();
      }

      final response = await dio.get(
        ApiConstants.adminEmployees,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw ServerException(data['message'] ?? 'Failed to fetch employees');
        }

        final rawList = data['data'];
        if (rawList is List) {
          return rawList
              .whereType<Map<String, dynamic>>()
              .map((e) => CreatedEmployeeModel.fromJson(e))
              .toList();
        }
        return <CreatedEmployeeModel>[];
      }

      throw const ServerException('Invalid response format from server');
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e, fallbackMessage: 'Failed to fetch employees. Please try again.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CreatedEmployeeModel> createEmployee({
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
      final cachedToken = sharedPreferences.getString('auth_bearer_token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'ngrok-skip-browser-warning': 'true',
      };
      if (cachedToken != null && cachedToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $cachedToken';
      }

      final payload = <String, dynamic>{
        'email': email,
        'employeeId': employeeId,
        'fullName': fullName,
        'locationId': locationId,
        'role': role,
        'contactNumber': contactNumber,
        if (locationName != null && locationName.trim().isNotEmpty)
          'locationName': locationName.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'log': longitude,
        if (longitude != null) 'lng': longitude,
        'reportingManagerEmployeeId': (reportingManagerEmployeeId != null &&
                reportingManagerEmployeeId.trim().isNotEmpty)
            ? reportingManagerEmployeeId.trim()
            : null,
      };

      final response = await dio.post(
        ApiConstants.adminEmployees,
        options: Options(headers: headers),
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw ServerException(data['message'] ?? 'Failed to create employee');
        }

        final employeeData = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;

        return CreatedEmployeeModel.fromJson(employeeData);
      }

      throw const ServerException('Invalid response format from server');
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e, fallbackMessage: 'Failed to create employee. Please try again.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ClientLocationModel> createLocation({
    required String clientName,
    required String locationName,
    required String address,
    String? city,
    required double latitude,
    required double longitude,
    required double allowedRadius,
  }) async {
    try {
      final cachedToken = sharedPreferences.getString('auth_bearer_token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'ngrok-skip-browser-warning': 'true',
      };
      if (cachedToken != null && cachedToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $cachedToken';
      }

      final payload = <String, dynamic>{
        'clientName': clientName,
        'locationName': locationName,
        'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'allowedRadius': allowedRadius,
      };

      final response = await dio.post(
        ApiConstants.adminLocations,
        options: Options(headers: headers),
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw ServerException(data['message'] ?? 'Failed to create location');
        }

        final locationData = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;

        return ClientLocationModel.fromJson(locationData);
      }

      throw const ServerException('Invalid response format from server');
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e, fallbackMessage: 'Failed to create location. Please try again.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<int>> downloadBulkUploadSample() async {
    try {
      final cachedToken = sharedPreferences.getString('auth_bearer_token');

      final headers = <String, String>{
        'Accept': '*/*',
        'ngrok-skip-browser-warning': 'true',
      };
      if (cachedToken != null && cachedToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $cachedToken';
      }

      final response = await dio.get<List<int>>(
        ApiConstants.adminBulkUploadSample,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
      );

      if (response.data != null) {
        return response.data!;
      }

      throw const ServerException('Failed to download sample file: empty response');
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(
        e,
        fallbackMessage: 'Failed to download sample file. Please try again.',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> bulkUploadEmployees({
    required String filePath,
    required String fileName,
    List<int>? fileBytes,
  }) async {
    try {
      final cachedToken = sharedPreferences.getString('auth_bearer_token');

      final headers = <String, String>{
        'Accept': '*/*',
        'ngrok-skip-browser-warning': 'true',
      };
      if (cachedToken != null && cachedToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $cachedToken';
      }

      MultipartFile multipartFile;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        multipartFile = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
      } else {
        multipartFile = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await dio.post(
        ApiConstants.adminBulkUpload,
        data: formData,
        options: Options(
          headers: headers,
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw ServerException(data['message'] ?? 'Bulk upload failed');
        }
        return data;
      }

      return {'success': true, 'message': 'Employees uploaded successfully'};
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(
        e,
        fallbackMessage: 'Failed to upload employees file. Please try again.',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
