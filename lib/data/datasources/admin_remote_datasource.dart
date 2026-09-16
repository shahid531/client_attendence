import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/error_handler.dart';
import '../../core/errors/exceptions.dart';
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
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;
  final SharedPreferences sharedPreferences;

  AdminRemoteDataSourceImpl({
    required this.dio,
    required this.sharedPreferences,
  });

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
}
