import 'package:dio/dio.dart';
import 'exceptions.dart';

class ErrorHandler {
  /// Transforms DioException into a clean, human-readable ServerException.
  static ServerException handleDioError(
    DioException e, {
    String fallbackMessage = 'An error occurred. Please try again.',
  }) {
    // 1. Check if backend returned structured JSON error message
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'] ?? data['msg'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        final cleanMsg = msg.toString().trim();
        // Avoid raw HTML or internal technical traces
        if (!cleanMsg.startsWith('<') && !cleanMsg.contains('<!DOCTYPE')) {
          return ServerException(cleanMsg);
        }
      }
    }

    // 2. Check HTTP status codes (especially HTML / Gateway errors like 502, 503, 500)
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return const ServerException('Invalid request. Please check your input.');
        case 401:
          return const ServerException('Session expired. Please sign in again.');
        case 403:
          return const ServerException('Access denied. You do not have permission.');
        case 404:
          return const ServerException('Requested service not found.');
        case 500:
          return const ServerException('Internal server error. Please try again later.');
        case 502:
        case 503:
        case 504:
          return const ServerException('Server is temporarily unavailable. Please try again later.');
        default:
          return ServerException('Server error ($statusCode). Please try again later.');
      }
    }

    // 3. Check connection / timeout types
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerException('Connection timed out. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return const ServerException('Unable to connect to the server. Please check your internet connection.');
      case DioExceptionType.cancel:
        return const ServerException('Request was cancelled.');
      default:
        return ServerException(fallbackMessage);
    }
  }
}
