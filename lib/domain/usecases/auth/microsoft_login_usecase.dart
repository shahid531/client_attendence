import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class MicrosoftLoginUseCase implements UseCase<User, Map<String, dynamic>> {
  final AuthRepository repository;

  MicrosoftLoginUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(Map<String, dynamic> params) async {
    return await repository.loginWithMicrosoft(params);
  }
}
