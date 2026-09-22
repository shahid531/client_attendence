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

class LoadEmployeesEvent extends AdminEvent {
  final bool isRefresh;
  final String? name;

  const LoadEmployeesEvent({
    this.isRefresh = false,
    this.name,
  });

  @override
  List<Object?> get props => [isRefresh, name];
}

class LoadLocationsEvent extends AdminEvent {
  final bool isRefresh;
  final String? clientName;
  final String? city;

  const LoadLocationsEvent({
    this.isRefresh = false,
    this.clientName,
    this.city,
  });

  @override
  List<Object?> get props => [isRefresh, clientName, city];
}

class CreateLocationSubmittedEvent extends AdminEvent {
  final String clientName;
  final String locationName;
  final String address;
  final String? city;
  final double latitude;
  final double longitude;
  final double allowedRadius;

  const CreateLocationSubmittedEvent({
    required this.clientName,
    required this.locationName,
    required this.address,
    this.city,
    required this.latitude,
    required this.longitude,
    required this.allowedRadius,
  });

  @override
  List<Object?> get props => [
        clientName,
        locationName,
        address,
        city,
        latitude,
        longitude,
        allowedRadius,
      ];
}

class DownloadBulkSampleEvent extends AdminEvent {
  const DownloadBulkSampleEvent();
}

class BulkUploadEmployeesEvent extends AdminEvent {
  final String filePath;
  final String fileName;
  final List<int>? fileBytes;

  const BulkUploadEmployeesEvent({
    required this.filePath,
    required this.fileName,
    this.fileBytes,
  });

  @override
  List<Object?> get props => [filePath, fileName, fileBytes];
}

class ResetBulkUploadStateEvent extends AdminEvent {
  const ResetBulkUploadStateEvent();
}

