import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/version_util.dart';
import '../blocs/app_version/app_version_bloc.dart';
import '../blocs/app_version/app_version_event.dart';
import '../blocs/app_version/app_version_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../widgets/force_update_dialog.dart';
import 'login_page.dart';
import 'main_navigation_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Start by checking the app version
    context.read<AppVersionBloc>().add(const CheckAppVersionEvent());
  }

  void _proceedToAuth() {
    if (!mounted) return;
    context.read<AuthBloc>().add(AppStartedEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AppVersionBloc, AppVersionState>(
          listener: (context, state) {
            if (state is AppVersionChecked) {
              if (state.updateType == AppUpdateType.force && state.versionInfo != null) {
                // Show blocking force update dialog
                ForceUpdateDialog.show(
                  context,
                  updateType: AppUpdateType.force,
                  currentVersion: state.currentVersion,
                  versionInfo: state.versionInfo!,
                );
              } else if (state.updateType == AppUpdateType.optional && state.versionInfo != null) {
                // Show optional update dialog with Later callback
                ForceUpdateDialog.show(
                  context,
                  updateType: AppUpdateType.optional,
                  currentVersion: state.currentVersion,
                  versionInfo: state.versionInfo!,
                  onDismissOptional: () {
                    _proceedToAuth();
                  },
                );
              } else {
                // No update required -> proceed with standard authentication check
                _proceedToAuth();
              }
            } else if (state is AppVersionFailure) {
              // On version check failure (e.g., offline), proceed with standard authentication check
              _proceedToAuth();
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthenticatedState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigationPage()),
              );
            } else if (state is UnauthenticatedState || state is AuthFailureState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.primaryNavy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/idealake_logo.png',
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
