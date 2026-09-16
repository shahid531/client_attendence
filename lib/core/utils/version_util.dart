import '../../domain/entities/app_version_info.dart';

enum AppUpdateType {
  none,
  optional,
  force,
}

class VersionUtil {
  /// Compares two version strings (e.g., "1.0.0", "1.2.1+5").
  /// Returns:
  ///  - negative integer if v1 < v2
  ///  - 0 if v1 == v2
  ///  - positive integer if v1 > v2
  static int compare(String v1, String v2) {
    final cleanV1 = _cleanVersion(v1);
    final cleanV2 = _cleanVersion(v2);

    final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }

  /// Determines the update type needed based on currentVersion and server AppVersionInfo.
  static AppUpdateType getUpdateType({
    required String currentVersion,
    required AppVersionInfo versionInfo,
  }) {
    // Check if minVersion is greater than app version -> Mandatory / Force Update
    if (versionInfo.minVersion.isNotEmpty &&
        compare(currentVersion, versionInfo.minVersion) < 0) {
      return AppUpdateType.force;
    }

    // Check if latestVersion is greater than app version -> Optional Update
    if (versionInfo.latestVersion.isNotEmpty &&
        compare(currentVersion, versionInfo.latestVersion) < 0) {
      return AppUpdateType.optional;
    }

    return AppUpdateType.none;
  }

  static String _cleanVersion(String version) {
    var cleaned = version.trim();
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }
    // Remove build metadata (e.g., +1, -beta, etc.)
    if (cleaned.contains('+')) {
      cleaned = cleaned.split('+').first;
    }
    if (cleaned.contains('-')) {
      cleaned = cleaned.split('-').first;
    }
    return cleaned;
  }
}
