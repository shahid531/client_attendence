import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(
    flavor: AppFlavor.testing,
    appName: 'Attendance (Testing)',
    baseUrl: 'https://clause-unpinned-wikipedia.ngrok-free.dev/api',
  );

  await initServiceLocator();
  runApp(const MyApp());
}
