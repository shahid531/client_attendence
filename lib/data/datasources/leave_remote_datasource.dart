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

  final List<LeaveRequestModel> _mockLeaveRequests = [
    LeaveRequestModel(
      id: 'req_001',
      title: 'John Smith - Casual Leave',
      requestType: 'Leave',
      startDate: DateTime.now().add(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 4)),
      reason: 'Personal family event in hometown.',
      status: 'Pending',
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    LeaveRequestModel(
      id: 'req_002',
      title: 'Sarah Lee - WFH Remote Request',
      requestType: 'WFH',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 2)),
      reason: 'Client deliverables sprint and remote sprint planning.',
      status: 'Pending',
      submittedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    LeaveRequestModel(
      id: 'req_003',
      title: 'Jane Doe - Attendance Regularization',
      requestType: 'Attendance Adjustment',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().subtract(const Duration(days: 2)),
      reason: 'Biometric device offline during evening clock-out.',
      status: 'Pending',
      submittedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    LeaveRequestModel(
      id: 'req_004',
      title: 'Michael Scott - Annual Vacation',
      requestType: 'Leave',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().subtract(const Duration(days: 7)),
      reason: 'Family trip approved in advance.',
      status: 'Approved',
      submittedAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    LeaveRequestModel(
      id: 'req_005',
      title: 'Dwight Schrute - Emergency Missed Punch',
      requestType: 'Attendance Adjustment',
      startDate: DateTime.now().subtract(const Duration(days: 14)),
      endDate: DateTime.now().subtract(const Duration(days: 14)),
      reason: 'Server maintenance during clock-in time.',
      status: 'Rejected',
      submittedAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

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
      status: 'Pending',
      submittedAt: DateTime.now(),
    );

    _mockLeaveRequests.insert(0, request);
    return request;
  }

  @override
  Future<List<LeaveRequestModel>> getLeaveRequests({String? status}) async {
    if (dio != null && sharedPreferences != null) {
      try {
        final token = sharedPreferences!.getString('auth_bearer_token');
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'ngrok-skip-browser-warning': 'true',
        };
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }

        final queryParams = <String, dynamic>{};
        if (status != null && status.isNotEmpty) {
          queryParams['status'] = status.toUpperCase();
        }

        final response = await dio!.get(
          '$_baseUrl/requests',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
          options: Options(headers: headers),
        );

        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Failed to fetch requests');
          }
          final resData = data['data'];
          if (resData is List) {
            return resData
                .map((item) => LeaveRequestModel.fromJson(item as Map<String, dynamic>))
                .toList();
          } else if (resData is Map<String, dynamic> && resData['content'] is List) {
            final contentList = resData['content'] as List;
            return contentList
                .map((item) => LeaveRequestModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        }
      } on DioException catch (e) {
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Failed to load requests (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network error while fetching requests');
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (status != null && status.isNotEmpty) {
      return _mockLeaveRequests
          .where((r) => r.status.toLowerCase() == status.toLowerCase())
          .toList();
    }
    return List<LeaveRequestModel>.from(_mockLeaveRequests);
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    String? remarks,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockLeaveRequests.indexWhere((r) => r.id == requestId || r.requestId == requestId);
    if (index != -1) {
      final old = _mockLeaveRequests[index];
      _mockLeaveRequests[index] = LeaveRequestModel(
        id: old.id,
        title: old.title,
        requestType: old.requestType,
        startDate: old.startDate,
        endDate: old.endDate,
        reason: remarks != null && remarks.isNotEmpty ? '${old.reason} (Note: $remarks)' : old.reason,
        status: status,
        submittedAt: old.submittedAt,
        employeeName: old.employeeName,
        employeeId: old.employeeId,
        requestId: old.requestId,
        requestedTimeOut: old.requestedTimeOut,
        assignedApproverName: old.assignedApproverName,
      );
    }
  }

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final pending = _mockLeaveRequests.where((r) => r.status == 'Pending').length;
    return DashboardStatsModel(
      totalHoursThisMonth: 164.5,
      daysPresent: 20,
      totalWorkingDays: 22,
      pendingRequests: pending,
      avgHoursPerDay: 8.2,
    );
  }
}

