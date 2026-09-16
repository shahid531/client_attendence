import 'package:flutter_test/flutter_test.dart';
import 'package:client_attendence/data/models/app_version_info_model.dart';
import 'package:client_attendence/domain/entities/app_version_info.dart';

void main() {
  const tModel = AppVersionInfoModel(
    platform: 'ANDROID',
    minVersion: '1.0.0',
    latestVersion: '1.2.0',
    updateMessage: 'Critical bug fixes',
    appLink: 'https://example.com/download.apk',
    forceUpdate: true,
  );

  test('should be a subclass of AppVersionInfo entity', () {
    expect(tModel, isA<AppVersionInfo>());
  });

  group('fromJson', () {
    test('should parse correctly from json map', () {
      final jsonMap = {
        'platform': 'ANDROID',
        'minVersion': '1.0.0',
        'latestVersion': '1.2.0',
        'updateMessage': 'Critical bug fixes',
        'appLink': 'https://example.com/download.apk',
        'forceUpdate': true,
      };

      final result = AppVersionInfoModel.fromJson(jsonMap);
      expect(result, tModel);
    });

    test('should parse string bool correctly', () {
      final jsonMap = {
        'platform': 'IOS',
        'minVersion': '1.0.0',
        'latestVersion': '1.1.0',
        'updateMessage': 'Update',
        'appLink': 'https://apps.apple.com/app',
        'forceUpdate': 'true',
      };

      final result = AppVersionInfoModel.fromJson(jsonMap);
      expect(result.forceUpdate, true);
    });
  });

  group('toJson', () {
    test('should return a JSON map containing proper data', () {
      final result = tModel.toJson();
      final expectedMap = {
        'platform': 'ANDROID',
        'minVersion': '1.0.0',
        'latestVersion': '1.2.0',
        'updateMessage': 'Critical bug fixes',
        'appLink': 'https://example.com/download.apk',
        'forceUpdate': true,
      };
      expect(result, expectedMap);
    });
  });
}
