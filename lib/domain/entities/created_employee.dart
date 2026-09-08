import 'package:equatable/equatable.dart';

class CreatedEmployee extends Equatable {
  final int? id;
  final String employeeId;
  final String fullName;
  final String email;
  final String? contactNumber;
  final String? reportingManagerEmployeeId;
  final String? reportingManagerName;
  final String? locationId;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? clientName;
  final String role;
  final String? status;
  final bool firstLogin;
  final String? temporaryPassword;
  final String? createdAt;
  final String? updatedAt;

  const CreatedEmployee({
    this.id,
    required this.employeeId,
    required this.fullName,
    required this.email,
    this.contactNumber,
    this.reportingManagerEmployeeId,
    this.reportingManagerName,
    this.locationId,
    this.locationName,
    this.latitude,
    this.longitude,
    this.clientName,
    required this.role,
    this.status,
    this.firstLogin = true,
    this.temporaryPassword,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        employeeId,
        fullName,
        email,
        contactNumber,
        reportingManagerEmployeeId,
        reportingManagerName,
        locationId,
        locationName,
        latitude,
        longitude,
        clientName,
        role,
        status,
        firstLogin,
        temporaryPassword,
        createdAt,
        updatedAt,
      ];
}

