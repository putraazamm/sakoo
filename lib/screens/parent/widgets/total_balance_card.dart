// /lib/screens/parent/widgets/total_balance_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sakoo/screens/parent/add_funds_page.dart';

import '../../../controllers/parent_dashboard_controller.dart';

class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ParentDashboardController controller =
        Get.find<ParentDashboardController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Balance',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),

        Obx(() {
          // fetch total balance from parentData. if the state is loading, the default value is 0.0
          final rawBalance = controller.parentData['balance'];
          double balanceValue = rawBalance != null
              ? double.parse(rawBalance.toString())
              : 0.0;

          // Format baki kepada 2 titik perpuluhan dan pisahkan untuk styling
          String balanceString = balanceValue.toStringAsFixed(2);
          List<String> parts = balanceString.split('.');
          String integerPart = parts[0];
          String decimalPart = '.${parts[1]}';

          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'RM ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Text(
                integerPart,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                decimalPart,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF252525).withOpacity(0.6),
                ),
              ),
            ],
          );
        }),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => const AddFundsPage());
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  'Add Funds',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Boleh panggil fungsi withdraw di sini nanti
                },
                icon: const Icon(
                  Icons.north_west,
                  size: 18,
                  color: Colors.black,
                ),
                label: const Text(
                  'Withdraw',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5E5E5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
