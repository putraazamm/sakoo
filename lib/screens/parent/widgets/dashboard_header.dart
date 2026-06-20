// lib/screens/parent/widgets/dashboard_header.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/parent_dashboard_controller.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final ParentDashboardController controller = Get.find<ParentDashboardController>();

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.person, color: Colors.grey, size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Greetings,',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Obx(() => Text(
              '${controller.parentData['name'] ?? 'Loading...'} !',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            )),
          ],
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}