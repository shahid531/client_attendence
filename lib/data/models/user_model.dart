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
    super.address,
    super.status,
    super.avatarUrl,
    required super.firstLogin,
    super.latitude,
    super.longitude,
    super.radius,
    super.timeIn,
    super.timeOut,
    super.totalHours,
    super.attendanceType,
    super.description,
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

    final locationMap = (json['location'] is Map<String, dynamic>)
        ? json['location'] as Map<String, dynamic>
        : null;

    final company = locationMap?['clientName']?.toString() ??
        json['clientName']?.toString() ??
        json['company']?.toString() ??
        locationMap?['locationName']?.toString() ??
        json['locationName']?.toString() ??
        'ClientSite HQ';

    final locationName = locationMap?['locationName']?.toString() ??
        json['locationName']?.toString();

    final address = locationMap?['address']?.toString() ??
        json['address']?.toString();

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final lat = parseDouble(locationMap?['latitude'] ??
        json['latitude'] ??
        json['lat'] ??
        json['officeLatitude'] ??
        json['locationLatitude']);

    final lng = parseDouble(locationMap?['longitude'] ??
        json['longitude'] ??
        json['long'] ??
        json['lng'] ??
        json['officeLongitude'] ??
        json['locationLongitude']);

    final rad = parseDouble(locationMap?['allowedRadius'] ??
        locationMap?['radius'] ??
        json['allowedRadius'] ??
        json['radius'] ??
        json['geofenceRadius'] ??
        json['locationRadius'] ??
        json['officeRadius']);

    final desc = json['description']?.toString() ??
        json['reason']?.toString() ??
        json['workDescription']?.toString() ??
        json['remarks']?.toString();

    return UserModel(
      id: empId,
      name: fullName,
      email: email,
      role: role,
      company: company,
      contactNumber: json['contactNumber']?.toString(),
      reportingManagerName: json['reportingManagerName']?.toString(),
      locationName: locationName,
      address: address,
      status: locationMap?['status']?.toString() ?? json['status']?.toString() ?? 'ACTIVE',
      avatarUrl: json['avatarUrl']?.toString(),
      firstLogin: json['firstLogin'] == true,
      latitude: lat,
      longitude: lng,
      radius: rad,
      timeIn: json['timeIn']?.toString(),
      timeOut: json['timeOut']?.toString(),
      totalHours: json['totalHours'],
      attendanceType: json['attendanceType']?.toString(),
      description: desc,
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
      'address': address,
      'status': status,
      'avatarUrl': avatarUrl,
      'firstLogin': firstLogin,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'totalHours': totalHours,
      'attendanceType': attendanceType,
      'description': description,
    };
  }
}
