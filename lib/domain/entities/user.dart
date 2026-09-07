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
  final String? status;
  final String? avatarUrl;
  final bool firstLogin;
  final double? latitude;
  final double? longitude;
  final double? radius;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.company,
    this.contactNumber,
    this.reportingManagerName,
    this.locationName,
    this.status,
    this.avatarUrl,
    this.firstLogin = false,
    this.latitude,
    this.longitude,
    this.radius,
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
        status,
        avatarUrl,
        firstLogin,
        latitude,
        longitude,
        radius,
      ];
}
