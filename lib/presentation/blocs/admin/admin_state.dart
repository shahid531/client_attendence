import 'package:equatable/equatable.dart';
import '../../../domain/entities/client_location.dart';
import '../../../domain/entities/created_employee.dart';

abstract class AdminState extends Equatable {
  final List<CreatedEmployee> employees;
  final bool isLoadingEmployees;
  final String? employeesError;
  final List<ClientLocation> locations;
  final bool isLoadingLocations;
  final String? locationsError;

  const AdminState({
    this.employees = const [],
    this.isLoadingEmployees = false,
    this.employeesError,
    this.locations = const [],
    this.isLoadingLocations = false,
    this.locationsError,
  });

  @override
  List<Object?> get props => [
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class AdminInitialState extends AdminState {
  const AdminInitialState({
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });
}

class EmployeesLoadingState extends AdminState {
  const EmployeesLoadingState({
    super.employees,
    super.isLoadingEmployees = true,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });
}

class EmployeesLoadedState extends AdminState {
  const EmployeesLoadedState({
    required super.employees,
    super.isLoadingEmployees = false,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });
}

class EmployeesErrorState extends AdminState {
  final String error;

  const EmployeesErrorState(
    this.error, {
    super.employees,
    super.isLoadingEmployees = false,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  }) : super(employeesError: error);

  @override
  List<Object?> get props => [
        error,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class LocationsLoadingState extends AdminState {
  const LocationsLoadingState({
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations = true,
    super.locationsError,
  });
}

class LocationsLoadedState extends AdminState {
  const LocationsLoadedState({
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    required super.locations,
    super.isLoadingLocations = false,
    super.locationsError,
  });
}

class LocationsErrorState extends AdminState {
  final String error;

  const LocationsErrorState(
    this.error, {
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations = false,
  }) : super(locationsError: error);

  @override
  List<Object?> get props => [
        error,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class AdminLoadingState extends AdminState {
  const AdminLoadingState({
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });
}

class CreateEmployeeSuccessState extends AdminState {
  final CreatedEmployee employee;
  final String message;

  const CreateEmployeeSuccessState({
    required this.employee,
    this.message = 'Employee created successfully',
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        employee,
        message,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class UpdateEmployeeLoadingState extends AdminState {
  const UpdateEmployeeLoadingState({
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });
}

class UpdateEmployeeSuccessState extends AdminState {
  final CreatedEmployee employee;
  final String message;

  const UpdateEmployeeSuccessState({
    required this.employee,
    this.message = 'Employee updated successfully',
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        employee,
        message,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class UpdateEmployeeFailureState extends AdminState {
  final String message;

  const UpdateEmployeeFailureState(
    this.message, {
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        message,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class AdminFailureState extends AdminState {
  final String message;

  const AdminFailureState(
    this.message, {
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        message,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class CreateLocationLoadingState extends AdminState {
  const CreateLocationLoadingState({
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });
}

class CreateLocationSuccessState extends AdminState {
  final ClientLocation createdLocation;
  final String message;

  const CreateLocationSuccessState({
    required this.createdLocation,
    this.message = 'Location created successfully',
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        createdLocation,
        message,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class CreateLocationFailureState extends AdminState {
  final String message;

  const CreateLocationFailureState(
    this.message, {
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        message,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class BulkSampleDownloadLoadingState extends AdminState {
  const BulkSampleDownloadLoadingState({
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });
}

class BulkSampleDownloadSuccessState extends AdminState {
  final String filePath;
  final String message;

  const BulkSampleDownloadSuccessState({
    required this.filePath,
    this.message = 'Sample file downloaded successfully',
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        filePath,
        message,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class BulkSampleDownloadFailureState extends AdminState {
  final String message;

  const BulkSampleDownloadFailureState(
    this.message, {
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        message,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class BulkUploadLoadingState extends AdminState {
  const BulkUploadLoadingState({
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });
}

class BulkUploadSuccessState extends AdminState {
  final String message;
  final Map<String, dynamic>? data;

  const BulkUploadSuccessState({
    this.message = 'Employees uploaded successfully',
    this.data,
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        message,
        data,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}

class BulkUploadFailureState extends AdminState {
  final String message;

  const BulkUploadFailureState(
    this.message, {
    super.employees,
    super.isLoadingEmployees,
    super.employeesError,
    super.locations,
    super.isLoadingLocations,
    super.locationsError,
  });

  @override
  List<Object?> get props => [
        message,
        employees,
        isLoadingEmployees,
        employeesError,
        locations,
        isLoadingLocations,
        locationsError,
      ];
}


