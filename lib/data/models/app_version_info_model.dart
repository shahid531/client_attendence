import '../../domain/entities/app_version_info.dart';

class AppVersionInfoModel extends AppVersionInfo {
  const AppVersionInfoModel({
    required super.platform,
    required super.minVersion,
    required super.latestVersion,
    super.updateDate,
    required super.updateMessage,
    required super.appLink,
    required super.forceUpdate,
  });

  factory AppVersionInfoModel.fromJson(Map<String, dynamic> json) {
    return AppVersionInfoModel(
      platform: json['platform']?.toString() ?? '',
      minVersion: json['minVersion']?.toString() ?? '1.0.0',
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      updateDate: json['updateDate']?.toString(),
      updateMessage: (json['updateMessage'] != null &&
              json['updateMessage'].toString().trim().isNotEmpty)
          ? json['updateMessage'].toString()
          : 'A new update is available. Please update the app to the latest version to continue enjoying our features.',
      appLink: json['appLink']?.toString() ?? '',
      forceUpdate: json['forceUpdate'] == true ||
          json['forceUpdate']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'minVersion': minVersion,
      'latestVersion': latestVersion,
      'updateDate': updateDate,
      'updateMessage': updateMessage,
      'appLink': appLink,
      'forceUpdate': forceUpdate,
    };
  }
}
