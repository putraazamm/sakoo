import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'merchant_dashboard_page.dart';
import 'merchant_orders_page.dart';
import 'settings_page.dart';
import 'package:get/get.dart';
import 'merchant_menu_page.dart';
import '../../controllers/merchant_dashboard_controller.dart';

class MerchantMainShell extends StatefulWidget {
  const MerchantMainShell({Key? key}) : super(key: key);

  @override
  State<MerchantMainShell> createState() => _MerchantMainShellState();
}

class _MerchantMainShellState extends State<MerchantMainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<MerchantDashboardController>()) {
      Get.delete<MerchantDashboardController>(force: true);
    }
    Get.put(MerchantDashboardController());
  }

  final List<Widget> _pages = const [
    MerchantDashboardScreen(),
    MerchantOrdersPage(),
    MerchantMenuPage(),
    MerchantSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                GButton(icon: Icons.receipt_long_rounded, text: 'Orders'),
                GButton(icon: Icons.restaurant_menu_rounded, text: 'Menu'),
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
