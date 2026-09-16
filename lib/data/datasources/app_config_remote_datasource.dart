import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/error_handler.dart';
import '../../core/errors/exceptions.dart';
import '../models/app_version_info_model.dart';

abstract class AppConfigRemoteDataSource {
  Future<AppVersionInfoModel> checkAppVersion();
}

class AppConfigRemoteDataSourceImpl implements AppConfigRemoteDataSource {
  final Dio dio;

  AppConfigRemoteDataSourceImpl({
    required this.dio,
  });

  @override
  Future<AppVersionInfoModel> checkAppVersion() async {
    try {
      String platform = 'ANDROID';
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          platform = 'ANDROID';
        } else if (Platform.isIOS) {
          platform = 'IOS';
        }
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'ngrok-skip-browser-warning': 'true',
      };

      final response = await dio.get(
        ApiConstants.appVersion(platform),
        options: Options(headers: headers),
      );

      final data = response.data;
      print('[AppConfigRemoteDataSource] checkAppVersion response: $data');

      if (data is Map<String, dynamic>) {
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          return AppVersionInfoModel.fromJson(data['data'] as Map<String, dynamic>);
        }
        return AppVersionInfoModel.fromJson(data);
      }

      throw const ServerException('Invalid server response format for version check');
    } on DioException catch (e) {
      print('[AppConfigRemoteDataSource] DioException: ${e.response?.data ?? e.message}');
      throw ErrorHandler.handleDioError(e, fallbackMessage: 'Failed to check app version from server');
    } catch (e) {
      print('[AppConfigRemoteDataSource] Exception: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
