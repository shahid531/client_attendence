import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/created_employee.dart';
import '../../repositories/admin_repository.dart';

class GetEmployeesUseCase implements UseCase<List<CreatedEmployee>, NoParams> {
  final AdminRepository repository;

  GetEmployeesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CreatedEmployee>>> call(NoParams params) async {
    return await repository.getEmployees();
  }
}
