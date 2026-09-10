import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/leave_request.dart';
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

  Future<LeaveRequestsResult> getLeaveRequests({
    String? status,
    int page = 0,
    int pageSize = 10,
    String? employeeId,
    String? employeeName,
  });
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

  String _getRequestsEndpoint() {
    return '$_baseUrl/requests';
  }

  String _getUpdateRequestEndpoint(String requestId, String action) {
    final role = sharedPreferences?.getString('cached_user_role')?.trim().toUpperCase() ?? '';
    if (role == 'ADMIN') {
      return '$_baseUrl/admin/requests/$requestId/$action';
    } else if (role == 'RM' || role.startsWith('RM')) {
      return '$_baseUrl/rm/requests/$requestId/$action';
    } else {
      return '$_baseUrl/requests/$requestId/$action';
    }
  }

  @override
  Future<LeaveRequestsResult> getLeaveRequests({
    String? status,
    int page = 0,
    int pageSize = 10,
    String? employeeId,
    String? employeeName,
  }) async {
    if (dio != null && sharedPreferences != null) {
      try {
        final cachedToken = sharedPreferences!.getString('auth_bearer_token');
        if (cachedToken == null || cachedToken.isEmpty) {
          return const LeaveRequestsResult(requests: []);
        }
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Bearer $cachedToken',
        };

        final queryParams = <String, dynamic>{
          'employeeId': employeeId ?? '',
          'employeeName': employeeName ?? '',
          'page': page,
          'pageSize': pageSize > 0 ? pageSize : 10,
          'status': (status != null && status.isNotEmpty)
              ? status.toUpperCase()
              : 'PENDING,APPROVED,REJECTED',
        };

        final endpoint = _getRequestsEndpoint();
        print('[LeaveRemoteDataSource] GET $endpoint with params: $queryParams');

        final response = await dio!.get(
          endpoint,
          queryParameters: queryParams,
          options: Options(headers: headers),
        );

        final data = response.data;
        print('[LeaveRemoteDataSource] GET $endpoint response: $data');

        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Failed to retrieve requests');
          }

          final resData = data['data'];
          if (resData is Map<String, dynamic>) {
            final contentList = resData['content'];
            List<LeaveRequestModel> list = [];
            if (contentList is List) {
              list = contentList
                  .map((item) => LeaveRequestModel.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            return LeaveRequestsResult(
              requests: list,
              page: resData['page'] is int ? resData['page'] as int : page,
              pageSize: resData['pageSize'] is int ? resData['pageSize'] as int : pageSize,
              totalElements: resData['totalElements'] is int
                  ? resData['totalElements'] as int
                  : list.length,
              totalPages: resData['totalPages'] is int ? resData['totalPages'] as int : 1,
              hasNext: resData['hasNext'] is bool ? resData['hasNext'] as bool : false,
              hasPrevious: resData['hasPrevious'] is bool ? resData['hasPrevious'] as bool : false,
            );
          } else if (resData is List) {
            final parsed = resData
                .map((item) => LeaveRequestModel.fromJson(item as Map<String, dynamic>))
                .toList();
            return LeaveRequestsResult(
              requests: parsed,
              page: page,
              pageSize: pageSize,
              totalElements: parsed.length,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            );
          }
        }
        return const LeaveRequestsResult(requests: []);
      } on DioException catch (e) {
        print('[LeaveRemoteDataSource] DioException on GET requests: ${e.response?.data ?? e.message}');
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Failed to fetch requests (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network error while fetching requests');
      } catch (e) {
        print('[LeaveRemoteDataSource] Exception on GET requests: $e');
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (status != null && status.isNotEmpty) {
      final statuses =
          status.toUpperCase().split(',').map((s) => s.trim()).toList();
      final filtered = _mockLeaveRequests
          .where((r) => statuses.contains(r.status.toUpperCase()))
          .toList();
      return LeaveRequestsResult(
        requests: filtered,
        page: page,
        pageSize: pageSize,
        totalElements: filtered.length,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      );
    }
    return LeaveRequestsResult(
      requests: List<LeaveRequestModel>.from(_mockLeaveRequests),
      page: page,
      pageSize: pageSize,
      totalElements: _mockLeaveRequests.length,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
    );
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

        final endpoint = _getUpdateRequestEndpoint(requestId, action);
        print('[LeaveRemoteDataSource] POST $endpoint with comments: $remarks');

        final response = await dio!.post(
          endpoint,
          data: {
            'comments': remarks ?? '',
          },
          options: Options(headers: headers),
        );

        final data = response.data;
        print('[LeaveRemoteDataSource] POST $endpoint response: $data');

        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Failed to update request');
          }
        }
        return;
      } on DioException catch (e) {
        print('[LeaveRemoteDataSource] DioException on POST update request $requestId: ${e.response?.data ?? e.message}');
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Failed to update request (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network connection error while updating request status');
      } catch (e) {
        print('[LeaveRemoteDataSource] Exception on POST update request $requestId: $e');
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

