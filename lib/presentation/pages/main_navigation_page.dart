import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
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
  final Set<int> _loadedIndices = {0};
  final GlobalKey<ApprovalsScreenState> _approvalsScreenKey =
      GlobalKey<ApprovalsScreenState>();
  final GlobalKey<RequestPageState> _requestPageKey =
      GlobalKey<RequestPageState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) => current is AuthenticatedState,
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
          ),
          if (isRM || isAdmin)
            _NavTabItem(
              page: ApprovalsScreen(key: _approvalsScreenKey),
              barItem: const BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Approvals',
              ),
              onSelected: () {
                _approvalsScreenKey.currentState?.refreshCurrentTab();
              },
            ),
          
            _NavTabItem(
              page: const HistoryPage(),
              barItem: const BottomNavigationBarItem(
                icon: Icon(Icons.note_alt_outlined),
                activeIcon: Icon(Icons.note_alt),
                label: 'History',
              ),
            ),
          if (!isAdmin)
            _NavTabItem(
              page: RequestPage(key: _requestPageKey),
              barItem: const BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Requests',
              ),
              onSelected: () {
                _requestPageKey.currentState?.refreshCurrentTab();
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
              children: List.generate(tabs.length, (index) {
                if (_loadedIndices.contains(index)) {
                  return tabs[index].page;
                }
                return const SizedBox.shrink();
              }),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _loadedIndices.add(index);
              });
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
