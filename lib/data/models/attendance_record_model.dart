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

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      checkInTime: json['checkInTime'] as String,
      checkOutTime: json['checkOutTime'] as String?,
      workType: json['workType'] as String? ?? 'GPS',
      location: json['location'] as String? ?? 'HQ Office',
      description: json['description'] as String? ?? '',
      totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Present',
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
