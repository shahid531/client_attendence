import '../../domain/entities/created_employee.dart';

class CreatedEmployeeModel extends CreatedEmployee {
  const CreatedEmployeeModel({
    super.id,
    required super.employeeId,
    required super.fullName,
    required super.email,
    super.contactNumber,
    super.reportingManagerEmployeeId,
    super.reportingManagerName,
    super.locationId,
    super.locationName,
    super.clientName,
    required super.role,
    super.status,
    super.firstLogin = true,
    super.temporaryPassword,
    super.createdAt,
    super.updatedAt,
  });

  factory CreatedEmployeeModel.fromJson(Map<String, dynamic> json) {
    return CreatedEmployeeModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      employeeId: json['employeeId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      contactNumber: json['contactNumber']?.toString(),
      reportingManagerEmployeeId: json['reportingManagerEmployeeId']?.toString(),
      reportingManagerName: json['reportingManagerName']?.toString(),
      locationId: json['locationId']?.toString(),
      locationName: json['locationName']?.toString(),
      clientName: json['clientName']?.toString(),
      role: json['role']?.toString() ?? 'RM',
      status: json['status']?.toString() ?? 'ACTIVE',
      firstLogin: json['firstLogin'] == true,
      temporaryPassword: json['temporaryPassword']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'fullName': fullName,
      'email': email,
      'contactNumber': contactNumber,
      'reportingManagerEmployeeId': reportingManagerEmployeeId,
      'reportingManagerName': reportingManagerName,
      'locationId': locationId,
      'locationName': locationName,
      'clientName': clientName,
      'role': role,
      'status': status,
      'firstLogin': firstLogin,
      'temporaryPassword': temporaryPassword,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
