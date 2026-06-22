import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'merchant_new_order_page.dart';
import '../../controllers/merchant_dashboard_controller.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MerchantDashboardController>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Sini sistem akan panggil balik data terbaru dari Supabase bila ditarik
            await controller.fetchDashboardData();
          },
          child: SingleChildScrollView(
            // WAJIB LETAK NI: Supaya skrin sentiasa boleh ditarik walaupun content pendek
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -- Header --
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'lib/assets/images/sakoo-merchant-logo.svg',
                        height: 50,
                      ),

                      // --- Merchant Name ---
                      Obx(
                        () => Text(
                          controller.merchantName.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // -- Account Balance --
                  const Text(
                    'Account balance',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RM ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // --- account balance amount ---
                      Obx(
                        () => Text(
                          controller.merchantBalance.value.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // -- Withdraw Button --
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Fungsi withdraw nanti
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF252525),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Withdraw',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // -- Recent Transactions Header --
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // 5. FILTER TARIKH (Guna Obx untuk tukar UI bila tarikh dipilih)
                      Obx(
                        () => GestureDetector(
                          onTap: () => controller.pickDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: controller.selectedDate.value != null
                                  ? Colors.black
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  controller.selectedDate.value != null
                                      ? "${controller.selectedDate.value!.day}/${controller.selectedDate.value!.month}/${controller.selectedDate.value!.year}"
                                      : 'Choose date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: controller.selectedDate.value != null
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                // Butang 'X' kecil untuk buang filter tarikh
                                if (controller.selectedDate.value != null) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => controller.clearDateFilter(),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // -- Transaction List Area --
                  // DIUBAH: Expanded dibuang supaya tidak crash dengan SingleChildScrollView
                  Obx(() {
                    // Tunjuk loading spinner kalau data tengah diambil
                    if (controller.isLoading.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 30.0),
                          child: CircularProgressIndicator(color: Colors.black),
                        ),
                      );
                    }

                    // Tunjuk empty state kalau tiada transaksi
                    if (controller.transactions.isEmpty) {
                      return Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'No recent transaction yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    // Tunjuk ListView kalau ada data transaksi
                    return ListView.builder(
                      shrinkWrap:
                          true, // WAJIB letak jika ListView berada dalam Column/Scrollview
                      physics:
                          const NeverScrollableScrollPhysics(), // Matikan scroll ListView supaya dia ikut scroll bapa dia (SingleChildScrollView)
                      itemCount: controller.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = controller.transactions[index];

                        final isWithdraw = tx['type'] == 'withdraw';
                        final amount = (tx['amount'] ?? 0).toStringAsFixed(2);

                        // Ambil nama child dari relasi 'child' table (kalau wujud)
                        final childName = tx['child']?['childName'] ?? 'Child';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isWithdraw
                                ? Colors.red[100]
                                : Colors.green[100],
                            child: Icon(
                              isWithdraw
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isWithdraw ? Colors.red : Colors.green,
                            ),
                          ),
                          title: Text(
                            isWithdraw ? 'Withdrawal' : 'Order from $childName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            tx['createdAt'] != null
                                ? DateFormat('dd MM yyyy').format(
                                    DateTime.parse(tx['createdAt']).toLocal(),
                                  )
                                : '',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '${isWithdraw ? '-' : '+'} RM$amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isWithdraw ? Colors.red : Colors.green,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      // -- Floating New Order Button --
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const MerchantNewOrderScreen());
        },
        backgroundColor: const Color(0xFF252525),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        label: const Text(
          '+ New order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
