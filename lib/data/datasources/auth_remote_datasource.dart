import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String username,
    required String password,
    String deviceId = 'flutter_app_01',
    String deviceModel = 'Mobile',
    String operatingSystem = 'Android',
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final SharedPreferences sharedPreferences;

  static const String _baseUrl = 'https://clause-unpinned-wikipedia.ngrok-free.dev/api';

  AuthRemoteDataSourceImpl({
    required this.dio,
    required this.sharedPreferences,
  });

  @override
  Future<UserModel> login({
    required String username,
    required String password,
    String deviceId = 'flutter_app_01',
    String deviceModel = 'Mobile',
    String operatingSystem = 'Android',
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

      final response = await dio.post(
        '$_baseUrl/auth/login',
        options: Options(headers: headers),
        data: {
          'username': username,
          'password': password,
          'deviceId': deviceId,
          'deviceModel': deviceModel,
          'operatingSystem': operatingSystem,
        },
      );

      final data = response.data;
      print('[AuthRemoteDataSource] Login response: $data');
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw ServerException(data['message'] ?? 'Authentication failed');
        }

        final responseData = (data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : data;

        final token = responseData['token']?.toString();
        if (token != null) {
          await sharedPreferences.setString('auth_bearer_token', token);
        }

        final user = UserModel.fromJson(responseData);

        await sharedPreferences.setString('cached_user_id', user.id);
        await sharedPreferences.setString('cached_user_email', user.email);
        await sharedPreferences.setString('cached_user_name', user.name);
        await sharedPreferences.setString('cached_user_role', user.role);
        await sharedPreferences.setBool('cached_first_login', user.firstLogin);

        return user;
      }

      throw const ServerException('Invalid server response format');
    } on DioException catch (e) {
      print('[AuthRemoteDataSource] Login DioException: ${e.response?.data ?? e.message}');
      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        final errMap = e.response!.data as Map<String, dynamic>;
        final message = errMap['message'] ?? 'Authentication failed (${e.response?.statusCode})';
        throw ServerException(message.toString());
      }
      throw ServerException(e.message ?? 'Network connection error. Please check backend connection.');
    } catch (e) {
      print('[AuthRemoteDataSource] Login Exception: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove('auth_bearer_token');
    await sharedPreferences.remove('cached_user_id');
    await sharedPreferences.remove('cached_user_email');
    await sharedPreferences.remove('cached_user_name');
    await sharedPreferences.remove('cached_user_role');
    await sharedPreferences.remove('cached_first_login');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final cachedToken = sharedPreferences.getString('auth_bearer_token');
    if (cachedToken != null && cachedToken.isNotEmpty) {
      try {
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Bearer $cachedToken',
        };

        final response = await dio.get(
          '$_baseUrl/employee/profile',
          options: Options(headers: headers),
        );

        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final profileData = data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data;

          final user = UserModel.fromJson(profileData);

          if (user.id.isNotEmpty) {
            await sharedPreferences.setString('cached_user_id', user.id);
          }
          if (user.email.isNotEmpty) {
            await sharedPreferences.setString('cached_user_email', user.email);
          }
          if (user.name.isNotEmpty) {
            await sharedPreferences.setString('cached_user_name', user.name);
          }
          if (user.role.isNotEmpty) {
            await sharedPreferences.setString('cached_user_role', user.role);
          }
          await sharedPreferences.setBool('cached_first_login', user.firstLogin);

          return user;
        }
      } catch (e) {
        // Fallback to cached preferences if network fails
      }
    }

    final userId = sharedPreferences.getString('cached_user_id');
    final userEmail = sharedPreferences.getString('cached_user_email');
    final userName = sharedPreferences.getString('cached_user_name');
    final userRole = sharedPreferences.getString('cached_user_role');
    final firstLogin = sharedPreferences.getBool('cached_first_login') ?? false;

    if (userId != null && userId.isNotEmpty) {
      return UserModel(
        id: userId,
        name: userName ?? 'User',
        email: userEmail ?? '$userId@clientsite.com',
        role: userRole ?? 'RM',
        company: 'ClientSite HQ',
        firstLogin: firstLogin,
      );
    }
    return null;
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
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

      final response = await dio.post(
        '$_baseUrl/auth/change-password',
        options: Options(headers: headers),
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      final data = response.data;
      print('[AuthRemoteDataSource] Change-Password response: $data');
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw ServerException(data['message'] ?? 'Password update failed');
        }
      }

      await sharedPreferences.setBool('cached_first_login', false);
    } on DioException catch (e) {
      print('[AuthRemoteDataSource] Change-Password DioException: ${e.response?.data ?? e.message}');
      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        final errMap = e.response!.data as Map<String, dynamic>;
        final message = errMap['message'] ?? 'Password update failed (${e.response?.statusCode})';
        throw ServerException(message.toString());
      }
      throw ServerException(e.message ?? 'Network connection error while changing password.');
    } catch (e) {
      print('[AuthRemoteDataSource] Change-Password Exception: $e');

      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
