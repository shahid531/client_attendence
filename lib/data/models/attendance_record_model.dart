import 'package:intl/intl.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.id,
    required super.date,
    required super.checkInTime,
    super.checkOutTime,
    required super.workType,
    required super.location,
    required super.description,
    required super.totalHours,
    required super.status,
  });

  static double _parseTotalHours(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.contains(':')) {
        final parts = value.split(':');
        if (parts.length >= 2) {
          final hours = double.tryParse(parts[0]) ?? 0.0;
          final minutes = double.tryParse(parts[1]) ?? 0.0;
          return hours + (minutes / 60.0);
        }
      }
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static String _formatTimeString(dynamic value) {
    if (value == null) return '--:--';
    final str = value.toString();
    if (str.isEmpty || str == '--:--') return '--:--';
    if (str.contains('T') || (str.contains('-') && str.contains(':'))) {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) {
        return DateFormat('hh:mm a').format(parsed);
      }
    }
    return str;
  }

  static String? _formatNullableTimeString(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    if (str.isEmpty || str == 'null' || str == '--:--') return null;
    if (str.contains('T') || (str.contains('-') && str.contains(':'))) {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) {
        return DateFormat('hh:mm a').format(parsed);
      }
    }
    return str;
  }

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    final rawDate = json['attendanceDate'] ?? json['date'] ?? json['createdAt'];
    if (rawDate != null) {
      final parsed = DateTime.tryParse(rawDate.toString());
      if (parsed != null) {
        parsedDate = parsed.toLocal();
      }
    }

    final inTimeRaw = json['timeIn'] ?? json['checkInTime'] ?? json['inTime'] ?? json['clockInTime'];
    final outTimeRaw = json['timeOut'] ?? json['checkOutTime'] ?? json['outTime'] ?? json['clockOutTime'];

    final rawTotalHours = json['totalHours'] ?? json['hours'];
    double parsedTotalHours = _parseTotalHours(rawTotalHours);

    // If totalHours is 0.0 but both inTime and outTime are present, calculate exact difference
    if (parsedTotalHours == 0.0 && inTimeRaw != null && outTimeRaw != null && outTimeRaw.toString() != '--:--' && outTimeRaw.toString().isNotEmpty) {
      try {
        DateTime? inDt;
        DateTime? outDt;
        final inStr = inTimeRaw.toString();
        final outStr = outTimeRaw.toString();
        if (inStr.contains('T') || inStr.contains('-')) {
          inDt = DateTime.tryParse(inStr);
        }
        if (inDt == null) {
          try {
            final t = DateFormat('hh:mm a').parse(inStr);
            inDt = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, t.hour, t.minute);
          } catch (_) {}
        }

        if (outStr.contains('T') || outStr.contains('-')) {
          outDt = DateTime.tryParse(outStr);
        }
        if (outDt == null) {
          try {
            final t = DateFormat('hh:mm a').parse(outStr);
            outDt = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, t.hour, t.minute);
          } catch (_) {}
        }

        if (inDt != null && outDt != null) {
          final diffMins = outDt.difference(inDt).inMinutes;
          if (diffMins > 0) {
            parsedTotalHours = diffMins / 60.0;
          }
        }
      } catch (_) {}
    }

    return AttendanceRecordModel(
      id: (json['id'] ?? json['attendanceId'] ?? 'att_${parsedDate.millisecondsSinceEpoch}').toString(),
      date: parsedDate,
      checkInTime: _formatTimeString(inTimeRaw),
      checkOutTime: _formatNullableTimeString(outTimeRaw),
      workType: (json['attendanceType'] ?? json['workType'] ?? 'GPS').toString(),
      location: (json['location'] ?? json['locationName'] ?? json['clientName'] ?? 'HQ Office').toString(),
      description: (json['description'] ?? json['reason'] ?? json['notes'] ?? '').toString(),
      totalHours: parsedTotalHours,
      status: (json['attendanceStatus'] ?? json['status'] ?? 'Present').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'workType': workType,
      'location': location,
      'description': description,
      'totalHours': totalHours,
      'status': status,
    };
  }
}


