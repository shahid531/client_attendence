import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String company;
  final String? contactNumber;
  final String? reportingManagerName;
  final String? locationName;
  final String? address;
  final String? status;
  final String? avatarUrl;
  final bool firstLogin;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final String? timeIn;
  final String? timeOut;
  final dynamic totalHours;
  final String? attendanceType;
  final String? description;
  final String? timeInDescription;
  final String? timeOutDescription;

  double? get allowedRadius => radius;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.company,
    this.contactNumber,
    this.reportingManagerName,
    this.locationName,
    this.address,
    this.status,
    this.avatarUrl,
    this.firstLogin = false,
    this.latitude,
    this.longitude,
    this.radius,
    this.timeIn,
    this.timeOut,
    this.totalHours,
    this.attendanceType,
    this.description,
    this.timeInDescription,
    this.timeOutDescription,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        company,
        contactNumber,
        reportingManagerName,
        locationName,
        address,
        status,
        avatarUrl,
        firstLogin,
        latitude,
        longitude,
        radius,
        timeIn,
        timeOut,
        totalHours,
        attendanceType,
        description,
        timeInDescription,
        timeOutDescription,
      ];
}
