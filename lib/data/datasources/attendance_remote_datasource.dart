import 'dart:convert';
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

  Future<List<AttendanceRecordModel>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    String? filter,
    int page = 0,
    int size = 20,
  });
  Future<AttendanceRecordModel?> getTodayAttendance();
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final Dio? dio;
  final SharedPreferences? sharedPreferences;

  static const String _baseUrl = 'https://clause-unpinned-wikipedia.ngrok-free.dev/api';
  static const String _todayRecordPrefKey = 'today_attendance_record_data';
  static const String _todayWorkTypePrefKey = 'today_attendance_work_type';
  static const String _todayIsClockedInPrefKey = 'today_attendance_is_clocked_in';
  static const String _todayDatePrefKey = 'today_attendance_date';

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

  Future<void> _saveTodayRecord(AttendanceRecordModel? record) async {
    _todayRecord = record;
    if (sharedPreferences != null) {
      if (record != null) {
        final now = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        final isClockedIn = record.checkOutTime == null ||
            record.checkOutTime!.isEmpty ||
            record.checkOutTime == '--:--';

        await sharedPreferences!.setString(
          _todayRecordPrefKey,
          jsonEncode(record.toJson()),
        );
        await sharedPreferences!.setString(_todayDatePrefKey, todayStr);
        await sharedPreferences!.setString(_todayWorkTypePrefKey, record.workType);
        await sharedPreferences!.setBool(_todayIsClockedInPrefKey, isClockedIn);
      } else {
        await sharedPreferences!.remove(_todayRecordPrefKey);
        await sharedPreferences!.remove(_todayDatePrefKey);
        await sharedPreferences!.remove(_todayWorkTypePrefKey);
        await sharedPreferences!.remove(_todayIsClockedInPrefKey);
      }
    }
  }

  AttendanceRecordModel? _loadSavedTodayRecord() {
    if (sharedPreferences != null) {
      final savedDate = sharedPreferences!.getString(_todayDatePrefKey);
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      if (savedDate != null && savedDate != todayStr) {
        sharedPreferences!.remove(_todayRecordPrefKey);
        sharedPreferences!.remove(_todayDatePrefKey);
        sharedPreferences!.remove(_todayWorkTypePrefKey);
        sharedPreferences!.remove(_todayIsClockedInPrefKey);
        return null;
      }

      final saved = sharedPreferences!.getString(_todayRecordPrefKey);
      if (saved != null && saved.isNotEmpty) {
        try {
          final decoded = jsonDecode(saved);
          if (decoded is Map<String, dynamic>) {
            final model = AttendanceRecordModel.fromJson(decoded);
            final modelDateStr = DateFormat('yyyy-MM-dd').format(model.date);
            if (modelDateStr == todayStr) {
              return model;
            } else {
              sharedPreferences!.remove(_todayRecordPrefKey);
              sharedPreferences!.remove(_todayDatePrefKey);
              sharedPreferences!.remove(_todayWorkTypePrefKey);
              sharedPreferences!.remove(_todayIsClockedInPrefKey);
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  @override
  Future<AttendanceRecordModel> checkIn({
    required String workType,
    required String location,
    required String description,
  }) async {
    final now = DateTime.now();
    String timeStr = DateFormat('hh:mm a').format(now);
    String assignedId = 'att_${now.millisecondsSinceEpoch}';

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
        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Attendance time-in failed');
          }
          if (data['data'] is Map<String, dynamic>) {
            final resData = data['data'] as Map<String, dynamic>;
            if (resData['timeIn'] != null) {
              final parsed = DateTime.tryParse(resData['timeIn'].toString());
              timeStr = parsed != null
                  ? DateFormat('hh:mm a').format(parsed)
                  : resData['timeIn'].toString();
            }
            if (resData['id'] != null || resData['attendanceId'] != null) {
              assignedId = (resData['id'] ?? resData['attendanceId']).toString();
            }
          }
        }
      } on DioException catch (e) {
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Attendance time-in failed (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network connection error during time-in');
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }

    final record = AttendanceRecordModel(
      id: assignedId,
      date: now,
      checkInTime: timeStr,
      checkOutTime: null,
      workType: workType,
      location: location,
      description: description,
      totalHours: 0.0,
      status: 'Present',
    );

    await _saveTodayRecord(record);
    return record;
  }

  @override
  Future<AttendanceRecordModel> checkOut({
    required String recordId,
    required String description,
  }) async {
    final now = DateTime.now();
    String timeStr = DateFormat('hh:mm a').format(now);

    if (_todayRecord == null) {
      _todayRecord = _loadSavedTodayRecord();
    }

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
        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Attendance time-out failed');
          }
          if (data['data'] is Map<String, dynamic>) {
            final resData = data['data'] as Map<String, dynamic>;
            if (resData['timeOut'] != null) {
              final parsed = DateTime.tryParse(resData['timeOut'].toString());
              timeStr = parsed != null
                  ? DateFormat('hh:mm a').format(parsed)
                  : resData['timeOut'].toString();
            }
          }
        }
      } on DioException catch (e) {
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Attendance time-out failed (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network connection error during time-out');
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }

    final baseRecord = currentRecord ?? AttendanceRecordModel(
      id: recordId,
      date: now,
      checkInTime: timeStr,
      checkOutTime: null,
      workType: workType,
      location: 'Home Office',
      description: description,
      totalHours: 0.0,
      status: 'Present',
    );

    double computedHours = 0.0;
    try {
      DateTime? inDt;
      DateTime? outDt;
      final inStr = baseRecord.checkInTime;
      final outStr = timeStr;
      if (inStr.contains('T') || inStr.contains('-')) {
        inDt = DateTime.tryParse(inStr);
      }
      if (inDt == null) {
        try {
          final t = DateFormat('hh:mm a').parse(inStr);
          inDt = DateTime(baseRecord.date.year, baseRecord.date.month, baseRecord.date.day, t.hour, t.minute);
        } catch (_) {}
      }

      if (outStr.contains('T') || outStr.contains('-')) {
        outDt = DateTime.tryParse(outStr);
      }
      if (outDt == null) {
        try {
          final t = DateFormat('hh:mm a').parse(outStr);
          outDt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
        } catch (_) {}
      }

      if (inDt != null && outDt != null) {
        final diffMins = outDt.difference(inDt).inMinutes;
        if (diffMins > 0) {
          computedHours = diffMins / 60.0;
        }
      }
    } catch (_) {}

    final updatedRecord = AttendanceRecordModel(
      id: baseRecord.id,
      date: baseRecord.date,
      checkInTime: baseRecord.checkInTime,
      checkOutTime: timeStr,
      workType: baseRecord.workType,
      location: baseRecord.location,
      description: description.isNotEmpty ? description : baseRecord.description,
      totalHours: computedHours,
      status: 'Present',
    );

    await _saveTodayRecord(updatedRecord);
    _mockRecords.insert(0, updatedRecord);
    return updatedRecord;
  }

  @override
  Future<List<AttendanceRecordModel>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    String? filter,
    int page = 0,
    int size = 20,
  }) async {
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

        final queryParams = <String, dynamic>{
          'page': page,
          'size': size,
        };
        if (startDate != null && startDate.isNotEmpty) {
          queryParams['startDate'] = startDate;
        }
        if (endDate != null && endDate.isNotEmpty) {
          queryParams['endDate'] = endDate;
        }
        if (filter != null && filter.isNotEmpty) {
          queryParams['filter'] = filter;
        }

        final response = await dio!.get(
          '$_baseUrl/attendance/history',
          queryParameters: queryParams,
          options: Options(headers: headers),
        );

        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Failed to fetch attendance history');
          }
          final resData = data['data'];
          List<AttendanceRecordModel> historyList = [];
          if (resData is Map<String, dynamic> && resData['content'] is List) {
            final contentList = resData['content'] as List;
            historyList = contentList
                .map((item) => AttendanceRecordModel.fromJson(item as Map<String, dynamic>))
                .toList();
          } else if (resData is List) {
            historyList = resData
                .map((item) => AttendanceRecordModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }

          // Check if today's record exists in the history and sync
          final now = DateTime.now();
          final todayMatches = historyList.where((r) =>
              r.date.year == now.year &&
              r.date.month == now.month &&
              r.date.day == now.day).toList();
          if (todayMatches.isNotEmpty) {
            final latestToday = todayMatches.first;
            if (_todayRecord == null || (_todayRecord!.checkOutTime == null && latestToday.checkOutTime != null)) {
              await _saveTodayRecord(latestToday);
            }
          }

          return historyList;
        }
      } on DioException catch (e) {
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final errMap = e.response!.data as Map<String, dynamic>;
          final message = errMap['message'] ?? 'Failed to load history (${e.response?.statusCode})';
          throw ServerException(message.toString());
        }
        throw ServerException(e.message ?? 'Network connection error while fetching history');
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(e.toString());
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final list = List<AttendanceRecordModel>.from(_mockRecords);
    if (_todayRecord != null && !list.any((r) => r.id == _todayRecord!.id)) {
      list.insert(0, _todayRecord!);
    }
    return list;
  }

  @override
  Future<AttendanceRecordModel?> getTodayAttendance() async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (_todayRecord != null) {
      final recordDateStr = DateFormat('yyyy-MM-dd').format(_todayRecord!.date);
      if (recordDateStr != todayStr) {
        _todayRecord = null;
        await _saveTodayRecord(null);
      }
    } else {
      _todayRecord = _loadSavedTodayRecord();
    }
    await Future.delayed(const Duration(milliseconds: 100));
    return _todayRecord;
  }
}

