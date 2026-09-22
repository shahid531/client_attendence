import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/created_employee.dart';
import '../../repositories/admin_repository.dart';

class GetEmployeesUseCase implements UseCase<List<CreatedEmployee>, GetEmployeesParams> {
  final AdminRepository repository;

  GetEmployeesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CreatedEmployee>>> call(GetEmployeesParams params) async {
    return await repository.getEmployees(name: params.name);
  }
}

class GetEmployeesParams extends Equatable {
  final String? name;

  const GetEmployeesParams({this.name});

  @override
  List<Object?> get props => [name];
}
