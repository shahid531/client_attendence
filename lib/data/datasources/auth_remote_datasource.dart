import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/device_info_util.dart';
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

      final effectiveDeviceId = (deviceId.isNotEmpty && deviceId != 'flutter_app_01' && deviceId != 'flutter_device_01')
          ? deviceId
          : await DeviceInfoUtil.getDeviceId();
      final effectiveDeviceModel = (deviceModel.isNotEmpty && deviceModel != 'Mobile' && deviceModel != 'Flutter App')
          ? deviceModel
          : await DeviceInfoUtil.getDeviceModel();
      final effectiveOs = (operatingSystem.isNotEmpty && operatingSystem != 'Android')
          ? operatingSystem
          : await DeviceInfoUtil.getOperatingSystem();

      final response = await dio.post(
        '$_baseUrl/auth/login',
        options: Options(headers: headers),
        data: {
          'username': username,
          'password': password,
          'deviceId': effectiveDeviceId,
          'deviceModel': effectiveDeviceModel,
          'operatingSystem': effectiveOs,
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
        await sharedPreferences.setString('cached_user_company', user.company);
        if (user.locationName != null) await sharedPreferences.setString('cached_user_location_name', user.locationName!);
        if (user.address != null) await sharedPreferences.setString('cached_user_address', user.address!);
        await sharedPreferences.setBool('cached_first_login', user.firstLogin);
        if (user.latitude != null) await sharedPreferences.setDouble('cached_user_lat', user.latitude!);
        if (user.longitude != null) await sharedPreferences.setDouble('cached_user_lng', user.longitude!);
        if (user.radius != null) await sharedPreferences.setDouble('cached_user_radius', user.radius!);
        if (user.timeIn != null) await sharedPreferences.setString('cached_user_time_in', user.timeIn!);
        if (user.timeOut != null) await sharedPreferences.setString('cached_user_time_out', user.timeOut!);
        if (user.totalHours != null) await sharedPreferences.setString('cached_user_total_hours', user.totalHours.toString());
        final rememberMe = sharedPreferences.getBool('remember_me') ?? false;
        if (rememberMe) {
          await sharedPreferences.setString('last_logged_in_username', username);
          await sharedPreferences.setString('last_logged_in_password', password);
        } else {
          await sharedPreferences.remove('last_logged_in_username');
          await sharedPreferences.remove('last_logged_in_password');
        }

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
    final rememberMe = sharedPreferences.getBool('remember_me') ?? false;
    final lastUser = sharedPreferences.getString('last_logged_in_username');
    final lastPass = sharedPreferences.getString('last_logged_in_password');
    await sharedPreferences.clear();
    if (rememberMe) {
      await sharedPreferences.setBool('remember_me', true);
      if (lastUser != null) {
        await sharedPreferences.setString('last_logged_in_username', lastUser);
      }
      if (lastPass != null) {
        await sharedPreferences.setString('last_logged_in_password', lastPass);
      }
    }
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
          if (user.company.isNotEmpty) {
            await sharedPreferences.setString('cached_user_company', user.company);
          }
          if (user.locationName != null) {
            await sharedPreferences.setString('cached_user_location_name', user.locationName!);
          }
          if (user.address != null) {
            await sharedPreferences.setString('cached_user_address', user.address!);
          }
          await sharedPreferences.setBool('cached_first_login', user.firstLogin);
          if (user.latitude != null) await sharedPreferences.setDouble('cached_user_lat', user.latitude!);
          if (user.longitude != null) await sharedPreferences.setDouble('cached_user_lng', user.longitude!);
          if (user.radius != null) await sharedPreferences.setDouble('cached_user_radius', user.radius!);
          if (user.timeIn != null) await sharedPreferences.setString('cached_user_time_in', user.timeIn!);
          if (user.timeOut != null) await sharedPreferences.setString('cached_user_time_out', user.timeOut!);
          if (user.totalHours != null) await sharedPreferences.setString('cached_user_total_hours', user.totalHours.toString());
          if (user.attendanceType != null) await sharedPreferences.setString('cached_user_attendance_type', user.attendanceType!);

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
    final userCompany = sharedPreferences.getString('cached_user_company');
    final userLocationName = sharedPreferences.getString('cached_user_location_name');
    final userAddress = sharedPreferences.getString('cached_user_address');
    final firstLogin = sharedPreferences.getBool('cached_first_login') ?? false;
    final userLat = sharedPreferences.getDouble('cached_user_lat');
    final userLng = sharedPreferences.getDouble('cached_user_lng');
    final userRadius = sharedPreferences.getDouble('cached_user_radius');
    final userTimeIn = sharedPreferences.getString('cached_user_time_in');
    final userTimeOut = sharedPreferences.getString('cached_user_time_out');
    final userTotalHours = sharedPreferences.getString('cached_user_total_hours');
    final userAttendanceType = sharedPreferences.getString('cached_user_attendance_type');

    if (userId != null && userId.isNotEmpty) {
      return UserModel(
        id: userId,
        name: userName ?? 'User',
        email: userEmail ?? '$userId@clientsite.com',
        role: userRole ?? 'RM',
        company: userCompany ?? 'ClientSite HQ',
        locationName: userLocationName,
        address: userAddress,
        firstLogin: firstLogin,
        latitude: userLat,
        longitude: userLng,
        radius: userRadius,
        timeIn: userTimeIn,
        timeOut: userTimeOut,
        totalHours: userTotalHours,
        attendanceType: userAttendanceType,
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
