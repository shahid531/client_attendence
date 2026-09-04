import 'package:client_attendence/core/errors/failures.dart';
import 'package:client_attendence/domain/usecases/auth/change_password_usecase.dart';
import 'package:client_attendence/domain/repositories/auth_repository.dart';
import 'package:client_attendence/domain/entities/user.dart';
import 'package:client_attendence/presentation/blocs/change_password/change_password_bloc.dart';
import 'package:client_attendence/presentation/blocs/change_password/change_password_event.dart';
import 'package:client_attendence/presentation/blocs/change_password/change_password_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRepositoryForBlocTest implements AuthRepository {
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
    if (oldPassword == 'correctOld' && newPassword == 'validNewPass123') {
      return const Right(null);
    }
    return const Left(ServerFailure('Incorrect current password'));
  }
}

void main() {
  late ChangePasswordBloc bloc;
  late ChangePasswordUseCase useCase;
  late MockAuthRepositoryForBlocTest repository;

  setUp(() {
    repository = MockAuthRepositoryForBlocTest();
    useCase = ChangePasswordUseCase(repository);
    bloc = ChangePasswordBloc(changePasswordUseCase: useCase);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be ChangePasswordInitialState', () {
    expect(bloc.state, equals(ChangePasswordInitialState()));
  });

  test('should emit [ChangePasswordLoadingState, ChangePasswordSuccessState] on successful password update', () async {
    final expectedStates = [
      ChangePasswordLoadingState(),
      const ChangePasswordSuccessState('Password updated successfully!'),
    ];

    expectLater(bloc.stream, emitsInOrder(expectedStates));

    bloc.add(
      const ChangePasswordRequested(
        oldPassword: 'correctOld',
        newPassword: 'validNewPass123',
      ),
    );
  });

  test('should emit [ChangePasswordLoadingState, ChangePasswordFailureState] when update fails', () async {
    final expectedStates = [
      ChangePasswordLoadingState(),
      const ChangePasswordFailureState('Incorrect current password'),
    ];

    expectLater(bloc.stream, emitsInOrder(expectedStates));

    bloc.add(
      const ChangePasswordRequested(
        oldPassword: 'wrongPassword',
        newPassword: 'validNewPass123',
      ),
    );
  });
}
