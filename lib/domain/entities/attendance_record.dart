import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  final String id;
  final DateTime date;
  final String checkInTime;
  final String? checkOutTime;
  final String workType; // 'GPS' or 'WFH'
  final String location;
  final String description;
  final double totalHours;
  final String status; // 'Present', 'Half Day', 'On Leave'

  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    required this.workType,
    required this.location,
    required this.description,
    required this.totalHours,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        checkInTime,
        checkOutTime,
        workType,
        location,
        description,
        totalHours,
        status,
      ];
}
