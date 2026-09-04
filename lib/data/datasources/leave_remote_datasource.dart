import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../models/dashboard_stats_model.dart';
import '../models/leave_request_model.dart';

abstract class LeaveRemoteDataSource {
  Future<LeaveRequestModel> submitLeaveRequest({
    required String title,
    required String requestType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  });

  Future<List<LeaveRequestModel>> getLeaveRequests({String? status});
  Future<DashboardStatsModel> getDashboardStats();
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    String? remarks,
  });
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  final Dio? dio;
  final SharedPreferences? sharedPreferences;

  static const String _baseUrl = 'https://clause-unpinned-wikipedia.ngrok-free.dev/api';

  LeaveRemoteDataSourceImpl({
    this.dio,
    this.sharedPreferences,
  });

  final List<LeaveRequestModel> _mockLeaveRequests = [];

  @override
  Future<List<LeaveRequestModel>> getLeaveRequests({String? status}) async {
    if (dio != null && sharedPreferences != null) {
      try {
        final cachedToken = sharedPreferences!.getString('auth_bearer_token');
        final headers = <String, String>{
          'Accept': '*/*',
          'ngrok-skip-browser-warning': 'true',
        };
        if (cachedToken != null && cachedToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $cachedToken';
        }

        final queryParams = <String, dynamic>{};
        if (status != null && status.isNotEmpty) {
          queryParams['status'] = status.toUpperCase();
        }

        final response = await dio!.get(
          '$_baseUrl/admin/requests',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
          options: Options(headers: headers),
        );

        final data = response.data;
        print('[LeaveRemoteDataSource] GET /admin/requests response: $data');

        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Failed to retrieve requests');
          }

          final list = data['data'];
          if (list is List) {
            final parsed = list
                .map((item) => LeaveRequestModel.fromJson(item as Map<String, dynamic>))
                .toList();
            print('[LeaveRemoteDataSource] Successfully parsed ${parsed.length} requests');
            return parsed;
          }
        }
        return [];
      } on DioException catch (e) {
        print('[LeaveRemoteDataSource] DioException on GET /admin/requests: ${e.response?.data ?? e.message}');
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Failed to fetch requests (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network error while fetching requests');
      } catch (e) {
        print('[LeaveRemoteDataSource] Exception on GET /admin/requests: $e');
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (status != null && status.isNotEmpty) {
      return _mockLeaveRequests
          .where((r) => r.status.toUpperCase() == status.toUpperCase())
          .toList();
    }
    return List<LeaveRequestModel>.from(_mockLeaveRequests);
  }

  @override
  Future<LeaveRequestModel> submitLeaveRequest({
    required String title,
    required String requestType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final request = LeaveRequestModel(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      requestType: requestType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: 'PENDING',
      submittedAt: DateTime.now(),
    );

    _mockLeaveRequests.insert(0, request);
    return request;
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    String? remarks,
  }) async {
    if (dio != null && sharedPreferences != null) {
      try {
        final cachedToken = sharedPreferences!.getString('auth_bearer_token');
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'ngrok-skip-browser-warning': 'true',
        };
        if (cachedToken != null && cachedToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $cachedToken';
        }

        final action = (status.toUpperCase() == 'APPROVED' || status.toUpperCase() == 'APPROVE')
            ? 'approve'
            : 'reject';

        print('[LeaveRemoteDataSource] POST /admin/requests/$requestId/$action with comments: $remarks');

        final response = await dio!.post(
          '$_baseUrl/admin/requests/$requestId/$action',
          data: {
            'comments': remarks ?? '',
          },
          options: Options(headers: headers),
        );

        final data = response.data;
        print('[LeaveRemoteDataSource] POST /admin/requests/$requestId/$action response: $data');

        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Failed to update request');
          }
        }
        return;
      } on DioException catch (e) {
        print('[LeaveRemoteDataSource] DioException on POST /admin/requests/$requestId: ${e.response?.data ?? e.message}');
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Failed to update request (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network connection error while updating request status');
      } catch (e) {
        print('[LeaveRemoteDataSource] Exception on POST /admin/requests/$requestId: $e');
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }


    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockLeaveRequests.indexWhere((r) => r.id == requestId || r.requestId == requestId);
    if (index != -1) {
      final old = _mockLeaveRequests[index];
      _mockLeaveRequests[index] = LeaveRequestModel(
        id: old.id,
        requestId: old.requestId,
        employeeId: old.employeeId,
        employeeName: old.employeeName,
        attendanceId: old.attendanceId,
        title: old.title,
        requestType: old.requestType,
        startDate: old.startDate,
        endDate: old.endDate,
        reason: remarks != null && remarks.isNotEmpty ? '${old.reason} (Note: $remarks)' : old.reason,
        status: status,
        submittedAt: old.submittedAt,
        requestedTimeOut: old.requestedTimeOut,
        assignedApproverName: old.assignedApproverName,
        timeIn: old.timeIn,
        timeOut: old.timeOut,
      );
    }
  }



  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final pending = _mockLeaveRequests.where((r) => r.status.toUpperCase() == 'PENDING').length;
    return DashboardStatsModel(
      totalHoursThisMonth: 164.5,
      daysPresent: 20,
      totalWorkingDays: 22,
      pendingRequests: pending,
      avgHoursPerDay: 8.2,
    );
  }
}

