import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sakoo/controllers/parent_dashboard_controller.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/total_balance_card.dart';
import 'widgets/children_horizontal_list.dart';
import 'widgets/recent_activity_list.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ParentDashboardController controller = Get.find<ParentDashboardController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => controller.fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DashboardHeader(),
                    const SizedBox(height: 24),
                    const TotalBalanceCard(),
                    const SizedBox(height: 28),
                    const ChildrenHorizontalList(),
                    const SizedBox(height: 28),
                    const RecentActivityList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}