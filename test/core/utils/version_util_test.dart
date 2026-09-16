import 'package:flutter_test/flutter_test.dart';
import 'package:client_attendence/core/utils/version_util.dart';
import 'package:client_attendence/domain/entities/app_version_info.dart';

void main() {
  group('VersionUtil.compare', () {
    test('should return 0 when versions are equal', () {
      expect(VersionUtil.compare('1.0.0', '1.0.0'), 0);
      expect(VersionUtil.compare('v1.2.3', '1.2.3'), 0);
      expect(VersionUtil.compare('1.2.0+4', '1.2.0'), 0);
    });

    test('should return -1 when v1 < v2', () {
      expect(VersionUtil.compare('1.0.0', '1.0.1'), -1);
      expect(VersionUtil.compare('1.0.0', '1.1.0'), -1);
      expect(VersionUtil.compare('1.0.0', '2.0.0'), -1);
      expect(VersionUtil.compare('1.2', '1.2.1'), -1);
    });

    test('should return 1 when v1 > v2', () {
      expect(VersionUtil.compare('1.0.1', '1.0.0'), 1);
      expect(VersionUtil.compare('2.0.0', '1.9.9'), 1);
      expect(VersionUtil.compare('1.2.1', '1.2'), 1);
    });
  });

  group('VersionUtil.getUpdateType', () {
    test('should return AppUpdateType.force when currentVersion < minVersion', () {
      const info = AppVersionInfo(
        platform: 'ANDROID',
        minVersion: '1.2.0',
        latestVersion: '1.5.0',
        updateMessage: 'Please update',
        appLink: 'https://example.com/app',
        forceUpdate: false,
      );

      final result = VersionUtil.getUpdateType(
        currentVersion: '1.1.9',
        versionInfo: info,
      );

      expect(result, AppUpdateType.force);
    });

    test('should return AppUpdateType.force when forceUpdate is true and currentVersion < latestVersion', () {
      const info = AppVersionInfo(
        platform: 'ANDROID',
        minVersion: '1.0.0',
        latestVersion: '1.5.0',
        updateMessage: 'Please update',
        appLink: 'https://example.com/app',
        forceUpdate: true,
      );

      final result = VersionUtil.getUpdateType(
        currentVersion: '1.2.0',
        versionInfo: info,
      );

      expect(result, AppUpdateType.force);
    });

    test('should return AppUpdateType.optional when forceUpdate is false and currentVersion < latestVersion but >= minVersion', () {
      const info = AppVersionInfo(
        platform: 'ANDROID',
        minVersion: '1.0.0',
        latestVersion: '1.5.0',
        updateMessage: 'Please update',
        appLink: 'https://example.com/app',
        forceUpdate: false,
      );

      final result = VersionUtil.getUpdateType(
        currentVersion: '1.2.0',
        versionInfo: info,
      );

      expect(result, AppUpdateType.optional);
    });

    test('should return AppUpdateType.none when currentVersion >= latestVersion', () {
      const info = AppVersionInfo(
        platform: 'ANDROID',
        minVersion: '1.0.0',
        latestVersion: '1.5.0',
        updateMessage: 'Please update',
        appLink: 'https://example.com/app',
        forceUpdate: true,
      );

      final result = VersionUtil.getUpdateType(
        currentVersion: '1.5.0',
        versionInfo: info,
      );

      expect(result, AppUpdateType.none);
    });
  });
}
