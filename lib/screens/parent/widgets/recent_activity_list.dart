// /lib/screens/parent/widgets/recent_activity_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; 
import '../../../controllers/parent_dashboard_controller.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ParentDashboardController controller = Get.find();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[200],
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View all', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)), // <- button to view all transactions, can sort by date.
            ),
          ],
        ),
        const SizedBox(height: 12),
        
    
        Obx(() {
          if (controller.recentActivities.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text("No recent transactions.", style: TextStyle(color: Colors.grey)),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.recentActivities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activity = controller.recentActivities[index];
              
              String formattedDate = DateFormat('dd MMM yyyy').format(activity.createdAt);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02), 
                      blurRadius: 6, 
                      offset: const Offset(0, 2)
                    )
                  ]
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue[50],
                      child: Icon(Icons.store, color: Colors.blue[400], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.merchantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activity.childName} • ${activity.category}', 
                            style: TextStyle(color: Colors.grey[500], fontSize: 11)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RM ${activity.amount.toStringAsFixed(2)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)
                        ),
                        const SizedBox(height: 2),
                        Text(formattedDate, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }
}