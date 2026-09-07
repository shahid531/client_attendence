import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../models/created_employee_model.dart';

abstract class AdminRemoteDataSource {
  Future<CreatedEmployeeModel> createEmployee({
    required String email,
    required String employeeId,
    required String fullName,
    required String locationId,
    required String role,
    required String contactNumber,
    String? reportingManagerEmployeeId,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;
  final SharedPreferences sharedPreferences;

  static const String _baseUrl = 'https://clause-unpinned-wikipedia.ngrok-free.dev/api';

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

      final payload = {
        'email': email,
        'employeeId': employeeId,
        'fullName': fullName,
        'locationId': locationId,
        'role': role,
        'contactNumber': contactNumber,
        'reportingManagerEmployeeId': (reportingManagerEmployeeId != null &&
                reportingManagerEmployeeId.trim().isNotEmpty)
            ? reportingManagerEmployeeId.trim()
            : null,
      };

      final response = await dio.post(
        '$_baseUrl/admin/employees',
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
      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        final errMap = e.response!.data as Map<String, dynamic>;
        final message = errMap['message'] ??
            'Employee creation failed with code ${e.response?.statusCode}';
        throw ServerException(message.toString());
      }
      throw ServerException(
          e.message ?? 'Network error occurred while creating employee.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
