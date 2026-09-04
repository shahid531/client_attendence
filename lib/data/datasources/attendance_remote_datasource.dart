import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../models/attendance_record_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceRecordModel> checkIn({
    required String workType,
    required String location,
    required String description,
  });

  Future<AttendanceRecordModel> checkOut({
    required String recordId,
    required String description,
  });

  Future<List<AttendanceRecordModel>> getAttendanceHistory();
  Future<AttendanceRecordModel?> getTodayAttendance();
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final Dio? dio;
  final SharedPreferences? sharedPreferences;

  static const String _baseUrl = 'https://clause-unpinned-wikipedia.ngrok-free.dev/api';

  AttendanceRemoteDataSourceImpl({
    this.dio,
    this.sharedPreferences,
  });

  final List<AttendanceRecordModel> _mockRecords = [
    AttendanceRecordModel(
      id: 'att_001',
      date: DateTime.now().subtract(const Duration(days: 1)),
      checkInTime: '09:00 AM',
      checkOutTime: '05:30 PM',
      workType: 'GPS',
      location: 'HQ Building, 5th Floor',
      description: 'Worked on client attendance module refactoring.',
      totalHours: 8.5,
      status: 'Present',
    ),
    AttendanceRecordModel(
      id: 'att_002',
      date: DateTime.now().subtract(const Duration(days: 2)),
      checkInTime: '09:15 AM',
      checkOutTime: '05:45 PM',
      workType: 'WFH',
      location: 'Home Office (Verified IP)',
      description: 'Remote sprint planning & UI review.',
      totalHours: 8.5,
      status: 'Present',
    ),
    AttendanceRecordModel(
      id: 'att_003',
      date: DateTime.now().subtract(const Duration(days: 3)),
      checkInTime: '09:00 AM',
      checkOutTime: '01:30 PM',
      workType: 'GPS',
      location: 'HQ Building, 5th Floor',
      description: 'Half day attendance due to medical appointment.',
      totalHours: 4.5,
      status: 'Half Day',
    ),
  ];

  AttendanceRecordModel? _todayRecord;

  @override
  Future<AttendanceRecordModel> checkIn({
    required String workType,
    required String location,
    required String description,
  }) async {
    final now = DateTime.now();
    String timeStr = DateFormat('hh:mm a').format(now);

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

        final endpoint = workType == 'WFH'
            ? '$_baseUrl/attendance/wfh/time-in'
            : '$_baseUrl/attendance/check-in';

        final response = await dio!.post(
          endpoint,
          options: Options(headers: headers),
          data: {
            'reason': description,
            'deviceId': 'flutter_device_01',
          },
        );

        final data = response.data;
        print('[AttendanceRemoteDataSource] Check-In response: $data');

        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Attendance time-in failed');
          }
          if (data['data'] is Map<String, dynamic>) {
            final resData = data['data'] as Map<String, dynamic>;
            if (resData['timeIn'] != null) {
              timeStr = resData['timeIn'].toString();
            }
          }
        }
      } on DioException catch (e) {
        print('[AttendanceRemoteDataSource] Check-In DioException: ${e.response?.data ?? e.message}');
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Attendance time-in failed (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network connection error during time-in');
      } catch (e) {
        print('[AttendanceRemoteDataSource] Check-In Exception: $e');
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }

    final record = AttendanceRecordModel(
      id: 'att_${now.millisecondsSinceEpoch}',
      date: now,
      checkInTime: timeStr,
      checkOutTime: null,
      workType: workType,
      location: location,
      description: description,
      totalHours: 0.0,
      status: 'Present',
    );

    _todayRecord = record;
    return record;
  }

  @override
  Future<AttendanceRecordModel> checkOut({
    required String recordId,
    required String description,
  }) async {
    final now = DateTime.now();
    String timeStr = DateFormat('hh:mm a').format(now);

    final currentRecord = _todayRecord;
    final workType = currentRecord?.workType ?? 'WFH';

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

        final endpoint = workType == 'WFH'
            ? '$_baseUrl/attendance/wfh/time-out'
            : '$_baseUrl/attendance/check-out';

        final response = await dio!.post(
          endpoint,
          options: Options(headers: headers),
          data: {
            'reason': description,
            'deviceId': 'flutter_device_01',
          },
        );

        final data = response.data;
        print('[AttendanceRemoteDataSource] Check-Out response: $data');

        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Attendance time-out failed');
          }
          if (data['data'] is Map<String, dynamic>) {
            final resData = data['data'] as Map<String, dynamic>;
            if (resData['timeOut'] != null) {
              timeStr = resData['timeOut'].toString();
            }
          }
        }
      } on DioException catch (e) {
        print('[AttendanceRemoteDataSource] Check-Out DioException: ${e.response?.data ?? e.message}');
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Attendance time-out failed (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network connection error during time-out');
      } catch (e) {
        print('[AttendanceRemoteDataSource] Check-Out Exception: $e');
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }


    if (_todayRecord == null) {
      throw const ServerException('No active check-in record found for today');
    }

    final updatedRecord = AttendanceRecordModel(
      id: _todayRecord!.id,
      date: _todayRecord!.date,
      checkInTime: _todayRecord!.checkInTime,
      checkOutTime: timeStr,
      workType: _todayRecord!.workType,
      location: _todayRecord!.location,
      description: description.isNotEmpty ? description : _todayRecord!.description,
      totalHours: 8.0,
      status: 'Present',
    );

    _todayRecord = updatedRecord;
    _mockRecords.insert(0, updatedRecord);
    return updatedRecord;
  }

  @override
  Future<List<AttendanceRecordModel>> getAttendanceHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list = List<AttendanceRecordModel>.from(_mockRecords);
    if (_todayRecord != null && !list.any((r) => r.id == _todayRecord!.id)) {
      list.insert(0, _todayRecord!);
    }
    return list;
  }

  @override
  Future<AttendanceRecordModel?> getTodayAttendance() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _todayRecord;
  }
}
