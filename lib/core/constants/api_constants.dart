class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://clause-unpinned-wikipedia.ngrok-free.dev/api';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String userProfile = '$baseUrl/employee/profile';
  static const String changePassword = '$baseUrl/auth/change-password';

  // Attendance Endpoints
  static const String attendance = '$baseUrl/attendance';

  // Leave & WFH Request Endpoints
  static const String requests = '$baseUrl/requests';

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
  static const String adminEmployees = '$baseUrl/admin/employees';

  // App Version / Force Update Endpoints
  static String appVersion(String platform) => '$baseUrl/version/${platform.toUpperCase()}';
}
