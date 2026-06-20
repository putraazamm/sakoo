// lib/views/widgets/children_horizontal_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sakoo/screens/parent/add_child_page.dart';
import '../../../controllers/parent_dashboard_controller.dart';
import 'child_sakoo_card.dart';
import '../../parent/child_detail_page.dart';

class ChildrenHorizontalList extends StatelessWidget {
  const ChildrenHorizontalList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Tarik controller yang dah di-initialize sebelum ni
    final ParentDashboardController controller =
        Get.find<ParentDashboardController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bahagian Header (Children & + New Button)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Children',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Get.to(() => const AddChildPage());
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[200],
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '+ New',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Bahagian Senarai Kad
        SizedBox(
          height: 180,
          // 2. Guna Obx supaya UI automatik update bila tambah anak baru
          child: Obx(() {
            // Kalau tengah loading dan data kosong
            if (controller.isLoading.value && controller.childrenList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Kalau tak ada anak lagi dalam database
            if (controller.childrenList.isEmpty) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    "No children added yet.\nClick '+ New' to add.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              );
            }

            // 3. Paparkan data sebenar guna ListView.separated
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.childrenList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final child = controller.childrenList[index];

                return ChildSakooCard(
                  // Pass data sebenar dari database ke parameter kad baru kita
                  childNickname: child.childNickname.isNotEmpty
                      ? child.childNickname
                      : child.childName,
                  cardId: child.cardId,
                  balance: child.childBalance.toStringAsFixed(2),
                  isActive: child.isActive,
                  onTap: () {
                    // Letak function untuk redirect ke page detail kat sini nanti
                    Get.to(() => const ChildDetailScreen(), arguments: child);
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
