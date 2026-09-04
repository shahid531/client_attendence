import 'package:client_attendence/core/errors/failures.dart';
import 'package:client_attendence/domain/entities/user.dart';
import 'package:client_attendence/domain/repositories/auth_repository.dart';
import 'package:client_attendence/domain/usecases/auth/change_password_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRepositoryForChangePassword implements AuthRepository {
  @override
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
    String deviceId = 'flutter_app_01',
    String deviceModel = 'Mobile',
    String operatingSystem = 'Android',
  }) async {
    return const Right(
      User(
        id: '1',
        name: 'User',
        email: 'user@test.com',
        role: 'RM',
        company: 'ClientSite HQ',
      ),
    );
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (oldPassword == 'current123' && newPassword == 'newSecret456') {
      return const Right(null);
    }
    return const Left(ServerFailure('Invalid old password'));
  }
}

void main() {
  late ChangePasswordUseCase useCase;
  late MockAuthRepositoryForChangePassword mockRepository;

  setUp(() {
    mockRepository = MockAuthRepositoryForChangePassword();
    useCase = ChangePasswordUseCase(mockRepository);
  });

  test('should return Right(null) when change password succeeds', () async {
    final result = await useCase(
      const ChangePasswordParams(
        oldPassword: 'current123',
        newPassword: 'newSecret456',
      ),
    );

    expect(result.isRight(), true);
  });

  test('should return ServerFailure when change password fails with wrong credentials', () async {
    final result = await useCase(
      const ChangePasswordParams(
        oldPassword: 'wrongOldPassword',
        newPassword: 'newSecret456',
      ),
    );

    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, const ServerFailure('Invalid old password')),
      (_) => fail('Should have failed'),
    );
  });
}
