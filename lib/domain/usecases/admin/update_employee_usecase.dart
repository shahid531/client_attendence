import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/created_employee.dart';
import '../../repositories/admin_repository.dart';

class UpdateEmployeeUseCase
    implements UseCase<CreatedEmployee, UpdateEmployeeParams> {
  final AdminRepository repository;

  UpdateEmployeeUseCase(this.repository);

  @override
  Future<Either<Failure, CreatedEmployee>> call(
      UpdateEmployeeParams params) async {
    return await repository.updateEmployee(
      id: params.id,
      fullName: params.fullName,
      email: params.email,
      contactNumber: params.contactNumber,
      role: params.role,
      status: params.status,
      locationId: params.locationId,
      reportingManagerEmployeeId: params.reportingManagerEmployeeId,
    );
  }
}

class UpdateEmployeeParams extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String contactNumber;
  final String role;
  final String? status;
  final String locationId;
  final String? reportingManagerEmployeeId;

  const UpdateEmployeeParams({
    required this.id,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.role,
    this.status,
    required this.locationId,
    this.reportingManagerEmployeeId,
  });

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        contactNumber,
        role,
        status,
        locationId,
        reportingManagerEmployeeId,
      ];
}
