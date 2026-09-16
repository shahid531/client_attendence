import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/version_util.dart';
import '../../../domain/usecases/app_config/check_app_version_usecase.dart';
import 'app_version_event.dart';
import 'app_version_state.dart';

class AppVersionBloc extends Bloc<AppVersionEvent, AppVersionState> {
  final CheckAppVersionUseCase checkAppVersionUseCase;

  AppVersionBloc({
    required this.checkAppVersionUseCase,
  }) : super(const AppVersionInitial()) {
    on<CheckAppVersionEvent>(_onCheckAppVersion);
  }

  Future<void> _onCheckAppVersion(
    CheckAppVersionEvent event,
    Emitter<AppVersionState> emit,
  ) async {
    emit(const AppVersionLoading());

    String currentVersion = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (_) {
      // Fallback default
    }

    final result = await checkAppVersionUseCase(NoParams());

    result.fold(
      (failure) {
        // When API is not yet ready or offline, fallback to no update required so user can proceed
        emit(AppVersionChecked(
          updateType: AppUpdateType.none,
          currentVersion: currentVersion,
        ));
      },
      (versionInfo) {
        final updateType = VersionUtil.getUpdateType(
          currentVersion: currentVersion,
          versionInfo: versionInfo,
        );

        emit(AppVersionChecked(
          updateType: updateType,
          currentVersion: currentVersion,
          versionInfo: versionInfo,
        ));
      },
    );
  }
}
