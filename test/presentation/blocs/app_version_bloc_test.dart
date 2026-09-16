import 'package:client_attendence/core/errors/failures.dart';
import 'package:client_attendence/core/utils/version_util.dart';
import 'package:client_attendence/domain/entities/app_version_info.dart';
import 'package:client_attendence/domain/repositories/app_config_repository.dart';
import 'package:client_attendence/domain/usecases/app_config/check_app_version_usecase.dart';
import 'package:client_attendence/presentation/blocs/app_version/app_version_bloc.dart';
import 'package:client_attendence/presentation/blocs/app_version/app_version_event.dart';
import 'package:client_attendence/presentation/blocs/app_version/app_version_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAppConfigRepository implements AppConfigRepository {
  final Either<Failure, AppVersionInfo> response;

  MockAppConfigRepository(this.response);

  @override
  Future<Either<Failure, AppVersionInfo>> checkAppVersion() async {
    return response;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initial state is AppVersionInitial', () {
    final repo = MockAppConfigRepository(const Right(AppVersionInfo(
      platform: 'ANDROID',
      minVersion: '1.0.0',
      latestVersion: '1.0.0',
      updateMessage: '',
      appLink: '',
      forceUpdate: false,
    )));
    final bloc = AppVersionBloc(checkAppVersionUseCase: CheckAppVersionUseCase(repo));
    expect(bloc.state, const AppVersionInitial());
    bloc.close();
  });

  test('emits [AppVersionLoading, AppVersionChecked] when check succeeds with update required', () async {
    const versionInfo = AppVersionInfo(
      platform: 'ANDROID',
      minVersion: '2.0.0',
      latestVersion: '2.5.0',
      updateMessage: 'Please update your app to continue.',
      appLink: 'https://example.com',
      forceUpdate: true,
    );

    final repo = MockAppConfigRepository(const Right(versionInfo));
    final bloc = AppVersionBloc(checkAppVersionUseCase: CheckAppVersionUseCase(repo));

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        const AppVersionLoading(),
        isA<AppVersionChecked>()
            .having((s) => s.updateType, 'updateType', AppUpdateType.force)
            .having((s) => s.versionInfo, 'versionInfo', versionInfo),
      ]),
    );

    bloc.add(const CheckAppVersionEvent());
    await expectation;
    await bloc.close();
  });

  test('emits [AppVersionLoading, AppVersionChecked(updateType: none)] when repository returns Failure', () async {
    final repo = MockAppConfigRepository(const Left(ServerFailure('Connection error')));
    final bloc = AppVersionBloc(checkAppVersionUseCase: CheckAppVersionUseCase(repo));

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        const AppVersionLoading(),
        isA<AppVersionChecked>()
            .having((s) => s.updateType, 'updateType', AppUpdateType.none),
      ]),
    );

    bloc.add(const CheckAppVersionEvent());
    await expectation;
    await bloc.close();
  });
}
