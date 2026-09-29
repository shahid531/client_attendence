import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(
    flavor: AppFlavor.dev,
    appName: 'Attendance (Dev)',
    baseUrl: 'https://attendence-dev-api.idealake.com/api',
  );

  await initServiceLocator();
  runApp(const MyApp());
}
