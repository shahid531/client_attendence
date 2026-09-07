import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.company,
    super.contactNumber,
    super.reportingManagerName,
    super.locationName,
    super.status,
    super.avatarUrl,
    required super.firstLogin,
    super.latitude,
    super.longitude,
    super.radius,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final empId = json['employeeId']?.toString() ??
        json['username']?.toString() ??
        json['id']?.toString() ??
        'EMP001';

    final fullName = json['fullName']?.toString() ??
        json['name']?.toString() ??
        'User';

    final email = json['email']?.toString() ??
        '$empId@clientsite.com';

    final role = json['role']?.toString() ?? 'Employee';

    final company = json['clientName']?.toString() ??
        json['company']?.toString() ??
        json['locationName']?.toString() ??
        'ClientSite HQ';

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final lat = parseDouble(json['latitude'] ??
        json['lat'] ??
        json['officeLatitude'] ??
        json['locationLatitude']);

    final lng = parseDouble(json['longitude'] ??
        json['long'] ??
        json['lng'] ??
        json['officeLongitude'] ??
        json['locationLongitude']);

    final rad = parseDouble(json['radius'] ??
        json['geofenceRadius'] ??
        json['locationRadius'] ??
        json['officeRadius']);

    return UserModel(
      id: empId,
      name: fullName,
      email: email,
      role: role,
      company: company,
      contactNumber: json['contactNumber']?.toString(),
      reportingManagerName: json['reportingManagerName']?.toString(),
      locationName: json['locationName']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      avatarUrl: json['avatarUrl']?.toString(),
      firstLogin: json['firstLogin'] == true,
      latitude: lat,
      longitude: lng,
      radius: rad,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': id,
      'fullName': name,
      'email': email,
      'role': role,
      'clientName': company,
      'contactNumber': contactNumber,
      'reportingManagerName': reportingManagerName,
      'locationName': locationName,
      'status': status,
      'avatarUrl': avatarUrl,
      'firstLogin': firstLogin,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }
}
