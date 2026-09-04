import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/attendance/attendance_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/change_password/change_password_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/leave/leave_bloc.dart';
import 'presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
        BlocProvider<ChangePasswordBloc>(
          create: (_) => sl<ChangePasswordBloc>(),
        ),
        BlocProvider<AttendanceBloc>(
          create: (_) => sl<AttendanceBloc>(),
        ),
        BlocProvider<LeaveBloc>(
          create: (_) => sl<LeaveBloc>(),
        ),
        BlocProvider<DashboardBloc>(
          create: (_) => sl<DashboardBloc>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ClientSite Attendance',
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
      ),
    );
  }
}
