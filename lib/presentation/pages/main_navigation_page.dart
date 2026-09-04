import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'approvals_screen.dart';
import 'dashboard_page.dart';
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

  final List<Widget> _pages = const [
    HomePage(),
    ApprovalsScreen(),
    HistoryPage(),
    RequestPage(),
    //DashboardPage(),

    ProfilePage(),
  ];

  final List<String> _titles = const [
    'Clock In / Out',
    'Attendance History',
    'Requests & Approvals',
    'Performance Dashboard',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: Text(_titles[_currentIndex]),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.notifications_none_rounded),
      //       onPressed: () {
      //         ScaffoldMessenger.of(context).showSnackBar(
      //           const SnackBar(content: Text('No new notifications')),
      //         );
      //       },
      //     ),
      //     const SizedBox(width: 8),
      //   ],
      // ),
      body:SafeArea(child:  IndexedStack(
        index: _currentIndex,
        children: _pages,
      )),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryNavy,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            activeIcon: Icon(Icons.access_time_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Approvals',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_outlined),
            activeIcon: Icon(Icons.note_alt),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
