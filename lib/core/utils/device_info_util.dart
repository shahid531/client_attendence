import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoUtil {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static const String _prefDeviceIdKey = 'cached_device_unique_id';

  static String? _cachedDeviceId;
  static String? _cachedDeviceModel;
  static String? _cachedOperatingSystem;

  /// Returns the unique device identifier for the current device.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefDeviceIdKey);
      if (savedId != null && savedId.isNotEmpty) {
        _cachedDeviceId = savedId;
        return savedId;
      }

      String deviceId = '';

      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        deviceId = 'web_${webInfo.vendor ?? 'browser'}_${webInfo.userAgent.hashCode}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        // androidInfo.id provides the unique build/device ID
        deviceId = androidInfo.id.isNotEmpty
            ? androidInfo.id
            : 'android_${androidInfo.fingerprint.hashCode}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios_${iosInfo.model.hashCode}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        deviceId = windowsInfo.deviceId.isNotEmpty
            ? windowsInfo.deviceId
            : 'win_${windowsInfo.computerName.hashCode}';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfoPlugin.macOsInfo;
        deviceId = macInfo.systemGUID ?? 'mac_${macInfo.computerName.hashCode}';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        deviceId = linuxInfo.machineId ?? 'linux_${linuxInfo.name.hashCode}';
      }

      if (deviceId.isEmpty) {
        deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}';
      }

      _cachedDeviceId = deviceId;
      await prefs.setString(_prefDeviceIdKey, deviceId);
      return deviceId;
    } catch (_) {
      final fallbackId = _cachedDeviceId ?? 'dev_${DateTime.now().millisecondsSinceEpoch}';
      _cachedDeviceId = fallbackId;
      return fallbackId;
    }
  }

  /// Returns the device model name (e.g. "Samsung SM-G998B", "Pixel 7").
  static Future<String> getDeviceModel() async {
    if (_cachedDeviceModel != null && _cachedDeviceModel!.isNotEmpty) {
      return _cachedDeviceModel!;
    }

    try {
      String model = 'Mobile';

      if (kIsWeb) {
        model = 'Web Browser';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        final manufacturer = androidInfo.manufacturer;
        final modelName = androidInfo.model;
        if (modelName.toLowerCase().startsWith(manufacturer.toLowerCase())) {
          model = modelName;
        } else {
          model = '$manufacturer $modelName';
        }
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        model = iosInfo.utsname.machine.isNotEmpty
            ? iosInfo.utsname.machine
            : iosInfo.name;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        model = windowsInfo.productName.isNotEmpty
            ? windowsInfo.productName
            : 'Windows PC';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfoPlugin.macOsInfo;
        model = macInfo.model;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        model = linuxInfo.prettyName;
      }

      _cachedDeviceModel = model;
      return model;
    } catch (_) {
      return _cachedDeviceModel ?? 'Mobile';
    }
  }

  /// Returns the operating system with version (e.g. "Android 14", "iOS 17.4").
  static Future<String> getOperatingSystem() async {
    if (_cachedOperatingSystem != null && _cachedOperatingSystem!.isNotEmpty) {
      return _cachedOperatingSystem!;
    }

    try {
      String os = 'Android';

      if (kIsWeb) {
        os = 'Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        os = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        os = 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        os = 'Windows';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfoPlugin.macOsInfo;
        os = 'macOS ${macInfo.osRelease}';
      } else if (Platform.isLinux) {
        os = 'Linux';
      }

      _cachedOperatingSystem = os;
      return os;
    } catch (_) {
      return _cachedOperatingSystem ?? Platform.operatingSystem;
    }
  }
}
