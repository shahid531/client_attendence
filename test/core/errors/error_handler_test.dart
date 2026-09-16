import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_attendence/core/errors/error_handler.dart';

void main() {
  group('ErrorHandler.handleDioError', () {
    test('should extract clean message from JSON error response', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 400,
          data: {'message': 'Invalid username or password'},
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result.message, 'Invalid username or password');
    });

    test('should return session expired message on 401 when no custom backend message is returned', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/employee/profile'),
        response: Response(
          requestOptions: RequestOptions(path: '/employee/profile'),
          statusCode: 401,
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result.message, 'Session expired. Please sign in again.');
    });

    test('should ignore HTML body and return clean status code message on 502', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/login'),
        type: DioExceptionType.badResponse,
        message: 'This exception was thrown because the response has a status code of 502...',
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 502,
          data: '<!DOCTYPE html><html><body>502 Bad Gateway</body></html>',
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result.message, 'Server is temporarily unavailable. Please try again later.');
    });

    test('should return internal server error message on 500', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/attendance'),
        response: Response(
          requestOptions: RequestOptions(path: '/attendance'),
          statusCode: 500,
          data: 'Internal Server Error',
        ),
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result.message, 'Internal server error. Please try again later.');
    });

    test('should return connection timeout message on timeout error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/attendance'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result.message, 'Connection timed out. Please check your internet connection.');
    });

    test('should return connection error message on network offline', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/attendance'),
        type: DioExceptionType.connectionError,
      );

      final result = ErrorHandler.handleDioError(dioError);
      expect(result.message, 'Unable to connect to the server. Please check your internet connection.');
    });
  });
}
