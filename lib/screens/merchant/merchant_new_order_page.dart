import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/merchant_dashboard_controller.dart';
import '../../controllers/merchant_new_order_controller.dart';

class MerchantNewOrderScreen extends StatelessWidget {
  const MerchantNewOrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderController = Get.put(MerchantNewOrderController());
    final dashboardController = Get.find<MerchantDashboardController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
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
                              Obx(
                                () => Text(
                                  dashboardController.merchantName.value,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
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
                                  Obx(
                                    () => Text(
                                      dashboardController.merchantBalance.value
                                          .toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
                    ],
                  ),
                ),
                // --- Menu/Item List ---
                Expanded(
                  child: Obx(() {
                    if (orderController.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF252525),
                        ),
                      );
                    }

                    if (orderController.menuItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No items yet on the list.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // group items by category
                    final grouped = <String, List<Map<String, dynamic>>>{};
                    for (var item in orderController.menuItems) {
                      final cat = item['category'] as String? ?? 'Others';
                      grouped.putIfAbsent(cat, () => []).add(item);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 150,
                      ),
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, catIndex) {
                        final category = grouped.keys.elementAt(catIndex);
                        final items = grouped[category]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 10,
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildMenuItem(item, orderController),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
                      child: Obx(
                        () => Text(
                          'Total: RM ${orderController.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Buttons Row
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _showAddItemDialog(context, orderController),
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
                              final isCartReady =
                                  orderController.totalPrice > 0;
                              return ElevatedButton(
                                onPressed: isCartReady
                                    ? () => orderController.proceedToPayment()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCartReady
                                      ? Colors.blue
                                      : Colors.grey[400],
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

  Widget _buildMenuItem(
    Map<String, dynamic> item,
    MerchantNewOrderController controller,
  ) {
    final id = item['id'] as String;
    final price = (item['price'] as num).toDouble();
    final stock = item['stock'] as int;

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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'RM ${price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 2),

              Obx(() {
                final qty = controller.cart[id] ?? 0;
                final remaining = stock - qty;
                return Text(
                  remaining <= 5 ? '$remaining left' : 'Stock: $remaining',
                  style: TextStyle(
                    fontSize: 11,
                    color: remaining <= 5 ? Colors.orange : Colors.grey[400],
                    fontWeight: remaining <= 5
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                );
              }),
            ],
          ),

          // Quantity Button (+ / -)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4A4A4A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                  onPressed: () => controller.decrement(id),
                ),
                Obx(() {
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
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
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

  void _showAddItemDialog(
    BuildContext context,
    MerchantNewOrderController controller,
  ) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = 'Food & Drink';
    final categories = ['Food & Drink', 'Snack', 'Beverage', 'Others'];
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add New Item',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // item name textfield
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      hintText: 'e.g. Fried Chicken',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // price textfield
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Price (RM)',
                      hintText: 'e.g. 5.50',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // stock textfield
                  TextFormField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Stock',
                      hintText: 'e.g. 50',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) {
                        return 'Enter a whole number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => selectedCategory = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Get.back();
                controller.addItem(
                  name: nameController.text,
                  price: double.parse(priceController.text.trim()),
                  category: selectedCategory,
                  stock: int.parse(stockController.text.trim()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF252525),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
              ),
              child: const Text('Add Item', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
