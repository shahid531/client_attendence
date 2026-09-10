import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/injection_container.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/models/attendance_record_model.dart';
import '../blocs/attendance/attendance_bloc.dart';
import '../blocs/attendance/attendance_event.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import 'dart:developer' as dev;
import '../blocs/auth/auth_state.dart';
import '../../core/utils/device_info_util.dart';
import '../../core/utils/snackbar_helper.dart';
import 'main_navigation_page.dart';
import 'change_password_page.dart';

class LoginPage extends StatefulWidget {
  final String? initialUsername;
  final String? initialPassword;

  const LoginPage({
    super.key,
    this.initialUsername,
    this.initialPassword,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername ?? '');
    _passwordController = TextEditingController(text: widget.initialPassword ?? '');
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = widget.initialUsername ?? prefs.getString('last_logged_in_username');
      final savedPass = widget.initialPassword ?? prefs.getString('last_logged_in_password');

      if (mounted) {
        if (savedUser != null && savedUser.isNotEmpty) {
          _usernameController.text = savedUser;
        }
        if (savedPass != null && savedPass.isNotEmpty) {
          _passwordController.text = savedPass;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final deviceModel = await DeviceInfoUtil.getDeviceModel();
      final operatingSystem = await DeviceInfoUtil.getOperatingSystem();

      if (!mounted) return;
      context.read<AuthBloc>().add(
            LoginSubmittedEvent(
              username: _usernameController.text.trim(),
              password: _passwordController.text.trim(),
              deviceId: deviceId,
              deviceModel: deviceModel,
              operatingSystem: operatingSystem,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          dev.log('Login firstLogin: ${state.user.firstLogin}');
          try {
            sl<AttendanceRemoteDataSource>().clearCache();
          } catch (_) {}

          if (state.user.timeIn != null &&
              state.user.timeIn!.trim().isNotEmpty &&
              state.user.timeIn != '--:--') {
            final type = (state.user.attendanceType != null &&
                    state.user.attendanceType!.trim().isNotEmpty)
                ? state.user.attendanceType!.trim()
                : 'GPS';
            final parsedHours =
                AttendanceRecordModel.parseTotalHours(state.user.totalHours);
            final record = AttendanceRecordModel(
              id: 'att_${state.user.id}_${DateTime.now().millisecondsSinceEpoch}',
              date: DateTime.tryParse(state.user.timeIn!) ?? DateTime.now(),
              checkInTime: state.user.timeIn!,
              checkOutTime: (state.user.timeOut != null &&
                      state.user.timeOut!.trim().isNotEmpty &&
                      state.user.timeOut != '--:--')
                  ? state.user.timeOut
                  : null,
              workType: type,
              location: type.toUpperCase() == 'WFH'
                  ? 'Home Office'
                  : (state.user.locationName ?? 'HQ Building, 5th Floor'),
              description: state.user.description ?? '',
              totalHours: parsedHours,
              status: 'Present',
            );
            try {
              sl<AttendanceRemoteDataSource>().saveTodayRecord(record);
            } catch (_) {}
          }

          context.read<AttendanceBloc>().add(ResetAttendanceEvent());

          if (state.user.firstLogin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ChangePasswordPage(isFirstLogin: true),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationPage()),
            );
          }
        } else if (state is AuthFailureState) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          size: 38,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Sign in to manage your daily attendance',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Username / Employee ID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: 'Enter username or employee ID',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _onLoginPressed,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
