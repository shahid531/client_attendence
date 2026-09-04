import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(
      username: params.username,
      password: params.password,
      deviceId: params.deviceId,
      deviceModel: params.deviceModel,
      operatingSystem: params.operatingSystem,
    );
  }
}

class LoginParams extends Equatable {
  final String username;
  final String password;
  final String deviceId;
  final String deviceModel;
  final String operatingSystem;

  const LoginParams({
    required this.username,
    required this.password,
    this.deviceId = 'flutter_app_01',
    this.deviceModel = 'Mobile',
    this.operatingSystem = 'Android',
  });

  @override
  List<Object?> get props => [username, password, deviceId, deviceModel, operatingSystem];
}
