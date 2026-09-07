import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/attendance/attendance_bloc.dart';
import '../blocs/attendance/attendance_event.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/leave/leave_bloc.dart';
import '../blocs/leave/leave_event.dart';
import 'approvals_screen.dart';
import 'create_employee_screen.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'request_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final roleUpper = (authState is AuthenticatedState)
            ? authState.user.role.trim().toUpperCase()
            : '';
        final isAdmin = roleUpper == 'ADMIN';
        final isRM = roleUpper == 'RM' || roleUpper.startsWith('RM');

        final List<_NavTabItem> tabs = [
          _NavTabItem(
            page: isAdmin ? const CreateEmployeeScreen() : const HomePage(),
            barItem: BottomNavigationBarItem(
              icon: Icon(isAdmin ? Icons.person_add_alt_outlined : Icons.access_time),
              activeIcon: Icon(isAdmin ? Icons.person_add_alt_1 : Icons.access_time_filled),
              label: isAdmin ? 'Create Emp' : 'Home',
            ),
            onSelected: () {
              if (!isAdmin) {
                context.read<AttendanceBloc>().add(LoadTodayAttendanceEvent());
              }
            },
          ),
          if (isRM)
            _NavTabItem(
              page: const ApprovalsScreen(),
              barItem: const BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Approvals',
              ),
              onSelected: () {
                context.read<LeaveBloc>().add(const LoadLeaveRequestsEvent(status: 'PENDING'));
              },
            ),
          _NavTabItem(
            page: const HistoryPage(),
            barItem: const BottomNavigationBarItem(
              icon: Icon(Icons.note_alt_outlined),
              activeIcon: Icon(Icons.note_alt),
              label: 'History',
            ),
            onSelected: () {
              context.read<AttendanceBloc>().add(LoadAttendanceHistoryEvent());
            },
          ),
          _NavTabItem(
            page: const RequestPage(),
            barItem: const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Requests',
            ),
            onSelected: () {
              context.read<LeaveBloc>().add(const LoadLeaveRequestsEvent());
            },
          ),
          _NavTabItem(
            page: const ProfilePage(),
            barItem: const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ),
        ];

        final safeIndex = _currentIndex < tabs.length ? _currentIndex : 0;

        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: safeIndex,
              children: tabs.map((t) => t.page).toList(),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              tabs[index].onSelected?.call();
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryNavy,
            unselectedItemColor: AppColors.textLight,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: tabs.map((t) => t.barItem).toList(),
          ),
        );
      },
    );
  }
}

class _NavTabItem {
  final Widget page;
  final BottomNavigationBarItem barItem;
  final VoidCallback? onSelected;

  const _NavTabItem({
    required this.page,
    required this.barItem,
    this.onSelected,
  });
}
