import 'package:equatable/equatable.dart';

class AppVersionInfo extends Equatable {
  final String platform;
  final String minVersion;
  final String latestVersion;
  final String? updateDate;
  final String updateMessage;
  final String appLink;
  final bool forceUpdate;

  const AppVersionInfo({
    required this.platform,
    required this.minVersion,
    required this.latestVersion,
    this.updateDate,
    required this.updateMessage,
    required this.appLink,
    required this.forceUpdate,
  });

  @override
  List<Object?> get props => [
        platform,
        minVersion,
        latestVersion,
        updateDate,
        updateMessage,
        appLink,
        forceUpdate,
      ];
}
