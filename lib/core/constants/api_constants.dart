import '../config/app_config.dart';

class ApiConstants {
  // Base URL
  static String get baseUrl => AppConfig.shared.baseUrl;

  // Auth Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get microsoftLogin => '$baseUrl/auth/microsoft';
  static String get userProfile => '$baseUrl/employee/profile';
  static String get changePassword => '$baseUrl/auth/change-password';

  // Attendance Endpoints
  static String get attendance => '$baseUrl/attendance';
  static String get attendanceExport => '$baseUrl/attendance/export';
  static String attendanceRegularization(String attendanceId) =>
      '$baseUrl/attendance/$attendanceId/regularization';

  // Leave & WFH Request Endpoints
  static String get requests => '$baseUrl/requests';

  static String updateRequest({
    required String role,
    required String requestId,
    required String action,
  }) {
    final cleanRole = role.trim().toUpperCase();
    if (cleanRole == 'ADMIN') {
      return '$baseUrl/admin/requests/$requestId/$action';
    } else if (cleanRole == 'RM' || cleanRole.startsWith('RM')) {
      return '$baseUrl/rm/requests/$requestId/$action';
    } else {
      return '$baseUrl/requests/$requestId/$action';
    }
  }

  // Admin Endpoints
  static String get adminEmployees => '$baseUrl/admin/employees';
  static String get adminBulkUpload => '$baseUrl/admin/employees/bulk-upload';
  static String get adminBulkUploadSample => '$baseUrl/admin/employees/bulk-upload/sample';
  static String get adminLocations => '$baseUrl/admin/locations';
  static String adminLocationUpdate(dynamic id) => '$baseUrl/admin/locations/$id';

  // App Version / Force Update Endpoints
  static String appVersion(String platform) => '$baseUrl/version/${platform.toUpperCase()}';
}
