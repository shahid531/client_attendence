import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/created_employee.dart';
import '../../repositories/admin_repository.dart';

class CreateEmployeeUseCase
    implements UseCase<CreatedEmployee, CreateEmployeeParams> {
  final AdminRepository repository;

  CreateEmployeeUseCase(this.repository);

  @override
  Future<Either<Failure, CreatedEmployee>> call(
      CreateEmployeeParams params) async {
    return await repository.createEmployee(
      email: params.email,
      employeeId: params.employeeId,
      fullName: params.fullName,
      locationId: params.locationId,
      locationName: params.locationName,
      latitude: params.latitude,
      longitude: params.longitude,
      role: params.role,
      contactNumber: params.contactNumber,
      reportingManagerEmployeeId: params.reportingManagerEmployeeId,
    );
  }
}

class CreateEmployeeParams extends Equatable {
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

  const CreateEmployeeParams({
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
