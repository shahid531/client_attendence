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

  Future<LeaveRequestsResult> getApprovalRequests({
    String? status,
    int page = 0,
    int pageSize = 10,
    String? employeeId,
    String? employeeName,
  });
  Future<DashboardStatsModel> getDashboardStats();
  Future<String> updateRequestStatus({
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

  String _getUpdateRequestEndpoint(String requestId, String action) {
    return '$_baseUrl/requests/$requestId/$action';
  }

  Future<LeaveRequestsResult> _fetchRequestsFromApi(
    String endpoint,
    Map<String, dynamic> queryParams, {
    int page = 0,
    int pageSize = 10,
    String? statusFilter,
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
            final paginationMap = (resData['requests'] is Map<String, dynamic>)
                ? resData['requests'] as Map<String, dynamic>
                : resData;

            final contentList = paginationMap['content'] ?? resData['content'];
            List<LeaveRequestModel> list = [];
            if (contentList is List) {
              list = contentList
                  .map((item) => LeaveRequestModel.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            int? parseCount(dynamic value) {
              if (value == null) return null;
              if (value is int) return value;
              if (value is num) return value.toInt();
              return int.tryParse(value.toString());
            }

            final pendingCount = parseCount(resData['pendingCount'] ?? data['pendingCount']);
            final completedCount = parseCount(resData['completedCount'] ?? data['completedCount']);

            return LeaveRequestsResult(
              requests: list,
              page: paginationMap['page'] is int ? paginationMap['page'] as int : page,
              pageSize: paginationMap['pageSize'] is int ? paginationMap['pageSize'] as int : pageSize,
              totalElements: paginationMap['totalElements'] is int
                  ? paginationMap['totalElements'] as int
                  : list.length,
              totalPages: paginationMap['totalPages'] is int ? paginationMap['totalPages'] as int : 1,
              hasNext: paginationMap['hasNext'] is bool ? paginationMap['hasNext'] as bool : false,
              hasPrevious: paginationMap['hasPrevious'] is bool ? paginationMap['hasPrevious'] as bool : false,
              pendingCount: pendingCount,
              completedCount: completedCount,
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
        print('[LeaveRemoteDataSource] DioException on GET $endpoint: ${e.response?.data ?? e.message}');
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Failed to fetch requests (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network error while fetching requests');
      } catch (e) {
        print('[LeaveRemoteDataSource] Exception on GET $endpoint: $e');
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (statusFilter != null && statusFilter.isNotEmpty) {
      final statuses =
          statusFilter.toUpperCase().split(',').map((s) => s.trim()).toList();
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
  Future<LeaveRequestsResult> getLeaveRequests({
    String? status,
    int page = 0,
    int pageSize = 10,
    String? employeeId,
    String? employeeName,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize > 0 ? pageSize : 10,
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status.toUpperCase();
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      queryParams['employeeId'] = employeeId;
    }
    if (employeeName != null && employeeName.isNotEmpty) {
      queryParams['employeeName'] = employeeName;
    }
    return _fetchRequestsFromApi(
      '$_baseUrl/requests',
      queryParams,
      page: page,
      pageSize: pageSize,
      statusFilter: status,
    );
  }

  @override
  Future<LeaveRequestsResult> getApprovalRequests({
    String? status,
    int page = 0,
    int pageSize = 10,
    String? employeeId,
    String? employeeName,
  }) async {
    final queryParams = <String, dynamic>{
      'employeeId': employeeId ?? '',
      'employeeName': employeeName ?? '',
      'page': page,
      'pageSize': pageSize > 0 ? pageSize : 10,
      'status': (status != null && status.isNotEmpty)
          ? status.toUpperCase()
          : 'PENDING',
    };
    return _fetchRequestsFromApi(
      '$_baseUrl/requests/approvals',
      queryParams,
      page: page,
      pageSize: pageSize,
      statusFilter: status,
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
  Future<String> updateRequestStatus({
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
        final Map<String, dynamic> body = {};
        if (remarks != null && remarks.isNotEmpty) {
          body['comments'] = remarks;
        } else if (action == 'reject') {
          body['comments'] = '';
        }
        print('[LeaveRemoteDataSource] POST $endpoint with body: $body');

        final response = await dio!.post(
          endpoint,
          data: body.isNotEmpty ? body : null,
          options: Options(headers: headers),
        );

        final data = response.data;
        print('[LeaveRemoteDataSource] POST $endpoint response: $data');

        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Failed to update request');
          }
          return data['message']?.toString() ?? 'Request updated successfully';
        }
        return 'Request updated successfully';
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
    return status.toUpperCase() == 'APPROVED' ? 'Request approved successfully' : 'Request rejected successfully';
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

