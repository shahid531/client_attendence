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
    super.latitude,
    super.longitude,
    super.clientName,
    required super.role,
    super.status,
    super.firstLogin = true,
    super.temporaryPassword,
    super.createdAt,
    super.updatedAt,
  });

  factory CreatedEmployeeModel.fromJson(Map<String, dynamic> json) {
    double? parseCoord(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    final lat = parseCoord(json['latitude'] ?? json['lat']);
    final lng = parseCoord(json['longitude'] ?? json['lng'] ?? json['log']);

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
      latitude: lat,
      longitude: lng,
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
      'latitude': latitude,
      'longitude': longitude,
      'lat': latitude,
      'log': longitude,
      'lng': longitude,
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

