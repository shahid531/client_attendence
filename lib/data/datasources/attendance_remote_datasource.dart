import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/device_info_util.dart';
import '../models/attendance_record_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceRecordModel> checkIn({
    required String workType,
    required String location,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  });

  Future<AttendanceRecordModel> checkOut({
    required String recordId,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  });

  Future<List<AttendanceRecordModel>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    String? filter,
    int page = 0,
    int size = 20,
  });
  Future<AttendanceRecordModel?> getTodayAttendance();
  Future<void> saveTodayRecord(AttendanceRecordModel? record);
  void clearCache();
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final Dio? dio;
  final SharedPreferences? sharedPreferences;

  static const String _baseUrl = 'https://clause-unpinned-wikipedia.ngrok-free.dev/api';
  static const String _todayRecordPrefKey = 'today_attendance_record_data';
  static const String _todayWorkTypePrefKey = 'today_attendance_work_type';
  static const String _todayIsClockedInPrefKey = 'today_attendance_is_clocked_in';
  static const String _todayDatePrefKey = 'today_attendance_date';
  static const String _todayUserIdPrefKey = 'cached_attendance_user_id';

  AttendanceRemoteDataSourceImpl({
    this.dio,
    this.sharedPreferences,
  });

  @override
  void clearCache() {
    _todayRecord = null;
    if (sharedPreferences != null) {
      sharedPreferences!.remove(_todayRecordPrefKey);
      sharedPreferences!.remove(_todayDatePrefKey);
      sharedPreferences!.remove(_todayWorkTypePrefKey);
      sharedPreferences!.remove(_todayIsClockedInPrefKey);
      sharedPreferences!.remove(_todayUserIdPrefKey);
      sharedPreferences!.remove('selected_work_type_index');
    }
  }

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
  Future<void> saveTodayRecord(AttendanceRecordModel? record) async {
    _todayRecord = record;
    if (sharedPreferences != null) {
      if (record != null) {
        final now = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        final isClockedIn = record.checkOutTime == null ||
            record.checkOutTime!.isEmpty ||
            record.checkOutTime == '--:--';
        final currentUserId = sharedPreferences!.getString('cached_user_id') ?? '';

        await sharedPreferences!.setString(
          _todayRecordPrefKey,
          jsonEncode(record.toJson()),
        );
        await sharedPreferences!.setString(_todayDatePrefKey, todayStr);
        await sharedPreferences!.setString(_todayWorkTypePrefKey, record.workType);
        await sharedPreferences!.setBool(_todayIsClockedInPrefKey, isClockedIn);
        if (currentUserId.isNotEmpty) {
          await sharedPreferences!.setString(_todayUserIdPrefKey, currentUserId);
        }
      } else {
        await sharedPreferences!.remove(_todayRecordPrefKey);
        await sharedPreferences!.remove(_todayDatePrefKey);
        await sharedPreferences!.remove(_todayWorkTypePrefKey);
        await sharedPreferences!.remove(_todayIsClockedInPrefKey);
        await sharedPreferences!.remove(_todayUserIdPrefKey);
      }
    }
  }

  AttendanceRecordModel? _loadSavedTodayRecord() {
    if (sharedPreferences != null) {
      final savedDate = sharedPreferences!.getString(_todayDatePrefKey);
      final savedUserId = sharedPreferences!.getString(_todayUserIdPrefKey);
      final currentUserId = sharedPreferences!.getString('cached_user_id');
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      if ((savedDate != null && savedDate != todayStr) ||
          (savedUserId != null && currentUserId != null && currentUserId.isNotEmpty && savedUserId != currentUserId)) {
        sharedPreferences!.remove(_todayRecordPrefKey);
        sharedPreferences!.remove(_todayDatePrefKey);
        sharedPreferences!.remove(_todayWorkTypePrefKey);
        sharedPreferences!.remove(_todayIsClockedInPrefKey);
        sharedPreferences!.remove(_todayUserIdPrefKey);
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
              sharedPreferences!.remove(_todayUserIdPrefKey);
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
    double? latitude,
    double? longitude,
    String? deviceId,
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

        final isWfh = workType.toUpperCase() == 'WFH';
        final endpoint = isWfh
            ? '$_baseUrl/attendance/wfh/time-in'
            : '$_baseUrl/attendance/time-in';

        final effectiveDeviceId = (deviceId != null && deviceId.isNotEmpty && deviceId != 'string')
            ? deviceId
            : await DeviceInfoUtil.getDeviceId();

        final Map<String, dynamic> requestBody = isWfh
            ? {
                'reason': description,
                'deviceId': effectiveDeviceId,
              }
            : {
                'latitude': latitude ?? 18.58742586542344,
                'longitude': longitude ?? 73.73845322922567,
                'deviceId': effectiveDeviceId,
              };

        final response = await dio!.post(
          endpoint,
          options: Options(headers: headers),
          data: requestBody,
        );

        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Attendance time-in failed');
          }
          if (data['data'] is Map<String, dynamic>) {
            final resData = data['data'] as Map<String, dynamic>;
            final parsedModel = AttendanceRecordModel.fromJson(resData);
            final record = AttendanceRecordModel(
              id: parsedModel.id,
              date: parsedModel.date,
              checkInTime: parsedModel.checkInTime.isNotEmpty && parsedModel.checkInTime != '--:--'
                  ? parsedModel.checkInTime
                  : timeStr,
              checkOutTime: parsedModel.checkOutTime,
              workType: parsedModel.workType.isNotEmpty ? parsedModel.workType : workType,
              location: parsedModel.location.isNotEmpty && parsedModel.location != 'HQ Office'
                  ? parsedModel.location
                  : location,
              description: description,
              totalHours: parsedModel.totalHours,
              status: parsedModel.status.isNotEmpty ? parsedModel.status : 'Present',
            );
            await saveTodayRecord(record);
            return record;
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

    await saveTodayRecord(record);
    return record;
  }

  @override
  Future<AttendanceRecordModel> checkOut({
    required String recordId,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    String timeStr = DateFormat('hh:mm a').format(now);
    double computedHours = 0.0;

    if (_todayRecord == null) {
      _todayRecord = _loadSavedTodayRecord();
    }

    final currentRecord = _todayRecord;
    final workType = currentRecord?.workType ?? 'GPS';

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

        final isWfh = workType.toUpperCase() == 'WFH';
        final endpoint = isWfh
            ? '$_baseUrl/attendance/wfh/time-out'
            : '$_baseUrl/attendance/time-out';

        final effectiveDeviceId = (deviceId != null && deviceId.isNotEmpty && deviceId != 'string')
            ? deviceId
            : await DeviceInfoUtil.getDeviceId();

        final Map<String, dynamic> requestBody = isWfh
            ? {
                'reason': description,
                'deviceId': effectiveDeviceId,
              }
            : {
                'latitude': latitude ?? 18.58742586542344,
                'longitude': longitude ?? 73.73845322922567,
                'deviceId': effectiveDeviceId,
              };

        final response = await dio!.post(
          endpoint,
          options: Options(headers: headers),
          data: requestBody,
        );

        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == false) {
            throw ServerException(data['message']?.toString() ?? 'Attendance time-out failed');
          }
          if (data['data'] is Map<String, dynamic>) {
            final resData = data['data'] as Map<String, dynamic>;
            final parsedModel = AttendanceRecordModel.fromJson(resData);
            final updatedRecord = AttendanceRecordModel(
              id: parsedModel.id,
              date: parsedModel.date,
              checkInTime: parsedModel.checkInTime.isNotEmpty && parsedModel.checkInTime != '--:--'
                  ? parsedModel.checkInTime
                  : (currentRecord?.checkInTime ?? timeStr),
              checkOutTime: parsedModel.checkOutTime ?? timeStr,
              workType: parsedModel.workType.isNotEmpty ? parsedModel.workType : workType,
              location: parsedModel.location.isNotEmpty && parsedModel.location != 'HQ Office'
                  ? parsedModel.location
                  : (currentRecord?.location ?? 'HQ Building, 5th Floor'),
              description: description.isNotEmpty ? description : (currentRecord?.description ?? ''),
              totalHours: parsedModel.totalHours > 0 ? parsedModel.totalHours : computedHours,
              status: parsedModel.status.isNotEmpty ? parsedModel.status : 'Present',
            );

            await saveTodayRecord(updatedRecord);
            _mockRecords.insert(0, updatedRecord);
            return updatedRecord;
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

      if (computedHours <= 0.0 && inDt != null && outDt != null) {
        final diffSecs = outDt.difference(inDt).inSeconds;
        if (diffSecs > 0) {
          computedHours = diffSecs / 3600.0;
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

    await saveTodayRecord(updatedRecord);
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
        if (token == null || token.isEmpty) {
          return [];
        }
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Bearer $token',
        };

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

        final role = sharedPreferences?.getString('cached_user_role')?.trim().toUpperCase() ?? '';
        final endpoint = (role == 'ADMIN' || role.contains('ADMIN'))
            ? '$_baseUrl/admin/attendance'
            : (role == 'RM' || role.startsWith('RM'))
                ? '$_baseUrl/rm/attendance'
                : '$_baseUrl/attendance/history';

        final response = await dio!.get(
          endpoint,
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
    final currentUserId = sharedPreferences?.getString('cached_user_id');
    final savedUserId = sharedPreferences?.getString(_todayUserIdPrefKey);

    if (savedUserId != null && currentUserId != null && currentUserId.isNotEmpty && savedUserId != currentUserId) {
      clearCache();
      return null;
    }

    if (_todayRecord != null) {
      final recordDateStr = DateFormat('yyyy-MM-dd').format(_todayRecord!.date);
      if (recordDateStr != todayStr) {
        _todayRecord = null;
        await saveTodayRecord(null);
      }
    } else {
      _todayRecord = _loadSavedTodayRecord();
    }
    await Future.delayed(const Duration(milliseconds: 100));
    return _todayRecord;
  }
}

