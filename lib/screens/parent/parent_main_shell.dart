import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:sakoo/controllers/parent_dashboard_controller.dart';
import 'package:sakoo/screens/parent/analytics_page.dart';
import 'parent_dashboard_page.dart';
import 'settings_page.dart';

class ParentMainShell extends StatefulWidget {
  const ParentMainShell({Key? key}) : super(key: key);

  @override
  State<ParentMainShell> createState() => _ParentMainShellState();
}

class _ParentMainShellState extends State<ParentMainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ParentDashboardController>()) {
      Get.delete<ParentDashboardController>(force: true);
    }
    Get.put(ParentDashboardController());
  }

  final List<Widget> _pages = const [
    ParentDashboardPage(),
    AnalyticsPage(), 
    ParentSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.08)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: GNav(
              rippleColor: Colors.grey[200]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: const Color(0xFF252525),
              color: Colors.grey[600],
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Home'),
                GButton(icon: Icons.analytics, text: 'Analytics'),
                GButton(icon: Icons.settings_rounded, text: 'Settings'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
