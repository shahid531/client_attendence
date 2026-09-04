import 'package:client_attendence/core/errors/failures.dart';
import 'package:client_attendence/domain/entities/user.dart';
import 'package:client_attendence/domain/repositories/auth_repository.dart';
import 'package:client_attendence/domain/usecases/auth/login_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
    String deviceId = 'flutter_app_01',
    String deviceModel = 'Mobile',
    String operatingSystem = 'Android',
  }) async {
    if (username == 'ADMIN001' && password == 'Admin@12345') {
      return const Right(
        User(
          id: '1',
          name: 'ADMIN001',
          email: 'ADMIN001@test.com',
          role: 'Administrator',
          company: 'ClientSite HQ',
        ),
      );
    } else {
      return const Left(ServerFailure('Invalid credentials'));
    }
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
    return const Right(null);
  }
}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  test('should return User entity when login with valid credentials succeeds', () async {
    // Arrange
    const username = 'ADMIN001';
    const password = 'Admin@12345';

    // Act
    final result = await useCase(const LoginParams(username: username, password: password));

    // Assert
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Should not fail'),
      (user) {
        expect(user.name, username);
      },
    );
  });

  test('should return ServerFailure when login fails', () async {
    // Arrange
    const username = 'INVALID_USER';
    const password = 'wrong';

    // Act
    final result = await useCase(const LoginParams(username: username, password: password));

    // Assert
    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, const ServerFailure('Invalid credentials')),
      (user) => fail('Should fail'),
    );
  });
}
