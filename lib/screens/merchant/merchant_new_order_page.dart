import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/merchant_dashboard_controller.dart';
import '../../controllers/merchant_new_order_controller.dart';

class MerchantNewOrderScreen extends StatelessWidget {
  const MerchantNewOrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Daftarkan controller untuk New Order
    final orderController = Get.put(MerchantNewOrderController());
    
    // Ambil controller Dashboard untuk paparkan header merchant
    final dashboardController = Get.find<MerchantDashboardController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // --- Latar Belakang & Senarai Boleh Skrol ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'lib/assets/images/sakoo-merchant-logo.svg',
                            height: 50,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Nama Merchant dari Dashboard Controller
                              Obx(() => Text(
                                dashboardController.merchantName.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              )),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RM ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  // Balance Merchant dari Dashboard Controller
                                  Obx(() => Text(
                                    dashboardController.merchantBalance.value.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // --- Title ---
                      const Text(
                        'New order',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Food & Drink',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Senarai Menu ---
                Expanded(
                  child: Obx(() => ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 150, // Padding bawah elak terlindung
                    ),
                    itemCount: orderController.menuItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = orderController.menuItems[index];
                      return _buildMenuItem(item, orderController);
                    },
                  )),
                ),
              ],
            ),

            // --- Sticky Bottom Action Bar ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 30,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.8),
                      Colors.white,
                      Colors.white,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Total Price yang dikira secara automatik
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
                      child: Obx(() => Text(
                        'Total: RM ${orderController.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    // Buttons Row
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Fungsi nak tambah menu sendiri
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF252525),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                '+ New item',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 55,
                            child: Obx(() {
                              // Butang 'Next' akan gelap jika ada pesanan, dan kelabu jika kosong
                              final isCartReady = orderController.totalPrice > 0;
                              return ElevatedButton(
                                onPressed: isCartReady ? () => orderController.proceedToPayment() : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCartReady ? Colors.blue : Colors.grey[400],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Next >',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget dinaik taraf untuk menerima data dinamik
  Widget _buildMenuItem(Map<String, dynamic> item, MerchantNewOrderController controller) {
    int id = item['id'] as int;
    double price = item['price'] as double;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'].toString(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'RM ${price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),

          // Butang Kuantiti (+ / -)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4A4A4A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                  onPressed: () => controller.decrement(id),
                ),
                Obx(() {
                  // Dengar perubahan pada nilai kuantiti di dalam cart
                  int qty = controller.cart[id] ?? 0;
                  return Text(
                    qty.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  onPressed: () => controller.increment(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}