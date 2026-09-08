import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class CreateEmployeeSubmittedEvent extends AdminEvent {
  final String email;
  final String employeeId;
  final String fullName;
  final String locationId;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String role;
  final String contactNumber;
  final String? reportingManagerEmployeeId;

  const CreateEmployeeSubmittedEvent({
    required this.email,
    required this.employeeId,
    required this.fullName,
    required this.locationId,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.role,
    required this.contactNumber,
    this.reportingManagerEmployeeId,
  });

  @override
  List<Object?> get props => [
        email,
        employeeId,
        fullName,
        locationId,
        locationName,
        latitude,
        longitude,
        role,
        contactNumber,
        reportingManagerEmployeeId,
      ];
}

class ResetAdminStateEvent extends AdminEvent {}
