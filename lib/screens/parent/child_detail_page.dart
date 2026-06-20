// lib/screens/parent/child_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/child_detail_controller.dart';
// import '../../models/child_model.dart';

class ChildDetailScreen extends StatelessWidget {
  const ChildDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(ChildDetailController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Back Button & Title)
              Row(
                children: [
                  InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Children', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text('You can manage your children card here.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),

              // 2. Kad Sakoo & Fungsi NFC
              Center(
                child: Obx(() {
                  final child = controller.childData.value;
                  if (child == null) return const CircularProgressIndicator();

                  bool isLinked = child.cardId.trim().isNotEmpty;

                  return Column(
                    children: [
                      // Kad UI
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 280,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF252525), Color(0xFF4A4A4A), Color(0xFF1E1E1E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: SvgPicture.asset(
                                    'lib/assets/images/sakoo-logo-welcome-screen.svg',
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(child.childNickname.isNotEmpty ? child.childNickname : child.childName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isLinked ? child.cardId : 'NOT LINKED', 
                                      style: TextStyle(color: isLinked ? Colors.grey[400] : Colors.white, fontSize: 12, letterSpacing: 1),
                                    ),
                                    Icon(Icons.visibility_outlined, color: Colors.grey[400], size: 18),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('RM ${child.childBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isLinked && child.isActive ? const Color(0xFF1E3A2F) : const Color(0xFF6B6A1A),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isLinked && child.isActive ? 'ACTIVE' : 'NOT ACTIVE',
                                        style: TextStyle(
                                          color: isLinked && child.isActive ? const Color(0xFF6ED7A4) : Colors.yellow[300],
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          // Butang Edit kat penjuru kad
                          Positioned(
                            top: -10,
                            right: -10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
                              child: const Icon(Icons.edit, size: 14, color: Colors.black87),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Teks Status & Butang Link NFC
                      if (!isLinked) ...[
                        Text('${child.childNickname} is not linked to Sakoo card yet.', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: controller.isScanning.value ? null : () => controller.linkNfcCard(),
                          icon: const Icon(Icons.link, size: 16, color: Colors.black),
                          label: Text(controller.isScanning.value ? 'Scanning...' : 'Link', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          ),
                        ),
                      ] else ...[
                        Text('${child.childNickname} is successfully linked!', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                      ]
                    ],
                  );
                }),
              ),
              const SizedBox(height: 24),

              // 3. Add Funds & Withdraw Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add Funds', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B2B2B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_outward, size: 18, color: Colors.black87),
                    label: const Text('Withdraw', style: TextStyle(color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 4. Tabs (Recent Transactions & Weekly Summary)
              Row(
                children: [
                  const Text('Recent Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(width: 16),
                  Text('Weekly Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Kotak Transaksi Kosong (Sama macam frame biru kau)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    // Buang border biru lepas kau siap design betul2
                    // border: Border.all(color: Colors.blue, width: 2), 
                  ),
                  child: Center(
                    child: Text('No recent transactions.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}