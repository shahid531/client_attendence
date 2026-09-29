import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/sso_constants.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/azure_sso_service.dart';
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
import '../widgets/flowerpot_cracker_effect.dart';
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
  bool _rememberMe = false;
  bool _isSsoLoading = false;

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
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
        });

        if (rememberMe) {
          final savedUser = widget.initialUsername ?? prefs.getString('last_logged_in_username');
          final savedPass = widget.initialPassword ?? prefs.getString('last_logged_in_password');

          if (savedUser != null && savedUser.isNotEmpty) {
            _usernameController.text = savedUser;
          }
          if (savedPass != null && savedPass.isNotEmpty) {
            _passwordController.text = savedPass;
          }
        } else if (widget.initialUsername != null || widget.initialPassword != null) {
          if (widget.initialUsername != null) {
            _usernameController.text = widget.initialUsername!;
          }
          if (widget.initialPassword != null) {
            _passwordController.text = widget.initialPassword!;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _onRememberMeChanged(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', value);
      if (!value) {
        await prefs.remove('last_logged_in_username');
        await prefs.remove('last_logged_in_password');
      } else {
        if (_usernameController.text.trim().isNotEmpty) {
          await prefs.setString('last_logged_in_username', _usernameController.text.trim());
        }
        if (_passwordController.text.trim().isNotEmpty) {
          await prefs.setString('last_logged_in_password', _passwordController.text.trim());
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
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('last_logged_in_username', _usernameController.text.trim());
          await prefs.setString('last_logged_in_password', _passwordController.text.trim());
        } else {
          await prefs.remove('last_logged_in_username');
          await prefs.remove('last_logged_in_password');
        }
      } catch (_) {}

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
          if (_isSsoLoading) {
            setState(() {
              _isSsoLoading = false;
            });
          }
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
              description: state.user.timeInDescription ?? state.user.description ?? '',
              totalHours: parsedHours,
              status: 'Present',
              employeeId: state.user.id,
              employeeName: state.user.name,
              timeInDescription: state.user.timeInDescription,
              timeOutDescription: state.user.timeOutDescription,
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
          if (_isSsoLoading) {
            setState(() {
              _isSsoLoading = false;
            });
          }
          SnackbarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoadingState;
        final screenWidth = MediaQuery.of(context).size.width;
        final isWideScreen = screenWidth > 650;

        return Scaffold(
          backgroundColor: isWideScreen ? const Color(0xFFF8FAFC) : null,
          body: SafeArea(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: !isWideScreen),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: isWideScreen
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: isWideScreen ? 16.0 : 24.0,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWideScreen ? 440 : double.infinity,
                              ),
                              child: Container(
                                padding: isWideScreen
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 32.0,
                                        vertical: 24.0,
                                      )
                                    : EdgeInsets.zero,
                                decoration: isWideScreen
                                    ? BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      )
                                    : null,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: isWideScreen ? 0 : 40),
                                      const Center(
                                        child: FlowerpotCrackerLogo(),
                                      ),
                                      SizedBox(height: isWideScreen ? 12 : 24),
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
                                      const SizedBox(height: 6),
                                      const Center(
                                        child: Text(
                                          'Sign in to manage your daily attendance',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isWideScreen ? 18 : 40),
                                      const Text(
                                        'Username / Employee ID',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _usernameController,
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          hintText: 'Enter username or employee ID',
                                          prefixIcon: const Icon(Icons.person_outline),
                                          contentPadding: isWideScreen
                                              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                                              : null,
                                        ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Please enter your username';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: isWideScreen ? 14 : 20),
                                      const Text(
                                        'Password',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          hintText: 'Enter your password',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          contentPadding: isWideScreen
                                              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                                              : null,
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
                                      SizedBox(height: isWideScreen ? 8 : 12),
                                      InkWell(
                                        onTap: () {
                                          final newVal = !_rememberMe;
                                          setState(() {
                                            _rememberMe = newVal;
                                          });
                                          _onRememberMeChanged(newVal);
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: Checkbox(
                                                  value: _rememberMe,
                                                  activeColor: AppColors.primaryNavy,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  onChanged: (val) {
                                                    final newVal = val ?? false;
                                                    setState(() {
                                                      _rememberMe = newVal;
                                                    });
                                                    _onRememberMeChanged(newVal);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Remember me',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isWideScreen ? 16 : 24),
                                      Center(
                                        child: SizedBox(
                                          width: isWideScreen ? 240 : double.infinity,
                                          height: isWideScreen ? 44 : 50,
                                          child: ElevatedButton(
                                            onPressed: (isLoading || _isSsoLoading) ? null : _onLoginPressed,
                                            child: (isLoading && !_isSsoLoading)
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
                                      ),
                                      SizedBox(height: isWideScreen ? 12 : 20),
                                      Center(
                                        child: SizedBox(
                                          width: isWideScreen ? 240 : double.infinity,
                                          child: Row(
                                            children: const [
                                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 14),
                                                child: Text(
                                                  'OR',
                                                  style: TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isWideScreen ? 12 : 20),

                                      // Microsoft SSO Sign In Button
                                      Center(
                                        child: SizedBox(
                                          width: isWideScreen ? 260 : double.infinity,
                                          height: isWideScreen ? 44 : 50,
                                          child: OutlinedButton(
                                            onPressed:
                                                (_isSsoLoading || isLoading) ? null : _handleMicrosoftSso,
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              side: const BorderSide(
                                                color: Color(0xFFCBD5E1),
                                                width: 1.2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: _isSsoLoading
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        Color(0xFF0078D4),
                                                      ),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      _buildMicrosoftLogo(),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        'Sign in with Microsoft',
                                                        style: TextStyle(
                                                          color: Color(0xFF1E293B),
                                                          fontSize: 14.5,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isWideScreen ? 8 : 10),
                                      Center(
                                        child: Text(
                                          'Company Single Sign-On (SSO)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleMicrosoftSso() async {
    if (!SsoConstants.isConfigured) {
      _showSsoSetupInstructions();
      return;
    }

    setState(() {
      _isSsoLoading = true;
    });

    try {
      final ssoService = AzureSsoService();
      final result = await ssoService.signIn();

      if (!mounted) return;

      // Print full untruncated SSO access token for developer verification
      AzureSsoService.printFullToken(result.accessToken, label: 'SSO_ACCESS_TOKEN');

      if (result.accessToken != null && result.accessToken!.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_bearer_token', result.accessToken!);
        await prefs.setString('microsoft_access_token', result.accessToken!);
        if (result.refreshToken != null && result.refreshToken!.isNotEmpty) {
          await prefs.setString('microsoft_refresh_token', result.refreshToken!);
        }
      }

      final deviceId = await DeviceInfoUtil.getDeviceId();
      final deviceModel = await DeviceInfoUtil.getDeviceModel();
      final operatingSystem = await DeviceInfoUtil.getOperatingSystem();

      final payload = <String, dynamic>{
        'token_type': result.tokenType ?? 'Bearer',
        'scope': (result.scope != null && result.scope!.isNotEmpty)
            ? result.scope
            : SsoConstants.scopes.join(' '),
        'expires_in': result.expiresIn ?? 3600,
        'ext_expires_in': result.extExpiresIn ?? (result.expiresIn ?? 3600),
        'access_token': result.accessToken ?? '',
        'refresh_token': result.refreshToken ?? '',
        'refresh_token_expires_in': result.refreshTokenExpiresIn ?? 86399,
        'id_token': result.idToken ?? '',
        'email': result.email,
        'name': result.displayName,
        'client_info': result.clientInfo ?? '',
        'device_id': deviceId,
        'device_model': deviceModel,
        'operating_system': operatingSystem,
      };

      if (!mounted) return;
      context.read<AuthBloc>().add(
            MicrosoftLoginSubmittedEvent(payload: payload),
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSsoLoading = false;
        });
        SnackbarHelper.showError(
          context,
          'SSO Authentication: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  void _showSsoSetupInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF0078D4)),
            SizedBox(width: 10),
            Text(
              'SSO Setup Required',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'To test Microsoft SSO, please add your Tenant ID and Client ID in:',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF334155)),
            ),
            SizedBox(height: 10),
            SelectableText(
              'lib/core/constants/sso_constants.dart',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFF0284C7),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Required:\n• tenantId\n• clientId\n\n(Once pasted, tap "Sign in with Microsoft" again)',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrosoftLogo() {
    return SizedBox(
      width: 18,
      height: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, color: const Color(0xFFF25022)),
              const SizedBox(width: 2),
              Container(width: 8, height: 8, color: const Color(0xFF7FBA00)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, color: const Color(0xFF00A4EF)),
              const SizedBox(width: 2),
              Container(width: 8, height: 8, color: const Color(0xFFFFB900)),
            ],
          ),
        ],
      ),
    );
  }
}
