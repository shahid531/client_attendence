import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import 'change_password_page.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UnauthenticatedState) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final user = state is AuthenticatedState ? state.user : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user?.name ?? 'Saheed Ansari',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.role ?? 'Client Technical Lead',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined, color: AppColors.primaryNavy),
                      title: const Text('Email Address'),
                      subtitle: Text(user?.email ?? 'saheed@clientsite.com'),
                    ),
                    const Divider(height: 1, indent: 50),
                    ListTile(
                      leading: const Icon(Icons.business_outlined, color: AppColors.primaryNavy),
                      title: const Text('Company / Client'),
                      subtitle: Text(user?.company ?? 'ClientSite HQ'),
                    ),
                    const Divider(height: 1, indent: 50),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppColors.primaryNavy),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequestedEvent());
                  },
                  icon: const Icon(Icons.logout, color: AppColors.dangerRose),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.dangerRose,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.dangerRose),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
