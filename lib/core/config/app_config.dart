enum AppFlavor {
  dev,
  testing,
}

class AppConfig {
  final AppFlavor flavor;
  final String appName;
  final String baseUrl;

  static AppConfig? _instance;

  AppConfig._({
    required this.flavor,
    required this.appName,
    required this.baseUrl,
  });

  /// The active configuration singleton instance.
  /// Falls back to Dev flavor if accessed before initialization.
  static AppConfig get shared {
    _instance ??= AppConfig._(
      flavor: AppFlavor.dev,
      appName: 'Attendance (Dev)',
      baseUrl: 'https://attendence-dev-api.idealake.com/api',
    );
    return _instance!;
  }

  /// Initialize the active flavor configuration.
  static void initialize({
    required AppFlavor flavor,
    required String appName,
    required String baseUrl,
  }) {
    _instance = AppConfig._(
      flavor: flavor,
      appName: appName,
      baseUrl: baseUrl,
    );
  }

  bool get isDev => flavor == AppFlavor.dev;
  bool get isTesting => flavor == AppFlavor.testing;
}
