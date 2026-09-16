import 'package:equatable/equatable.dart';
import '../../../core/utils/version_util.dart';
import '../../../domain/entities/app_version_info.dart';

abstract class AppVersionState extends Equatable {
  const AppVersionState();

  @override
  List<Object?> get props => [];
}

class AppVersionInitial extends AppVersionState {
  const AppVersionInitial();
}

class AppVersionLoading extends AppVersionState {
  const AppVersionLoading();
}

class AppVersionChecked extends AppVersionState {
  final AppUpdateType updateType;
  final String currentVersion;
  final AppVersionInfo? versionInfo;

  const AppVersionChecked({
    required this.updateType,
    required this.currentVersion,
    this.versionInfo,
  });

  @override
  List<Object?> get props => [updateType, currentVersion, versionInfo];
}

class AppVersionFailure extends AppVersionState {
  final String message;
  final String currentVersion;

  const AppVersionFailure({
    required this.message,
    required this.currentVersion,
  });

  @override
  List<Object?> get props => [message, currentVersion];
}
