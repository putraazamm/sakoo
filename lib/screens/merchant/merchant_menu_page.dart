// lib/screens/merchant/merchant_menu_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/merchant_menu_controller.dart';

class MerchantMenuPage extends StatelessWidget {
  const MerchantMenuPage({Key? key}) : super(key: key);

  static const _categories = ['Food & Drink', 'Snack', 'Beverage', 'Others'];

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MerchantMenuController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manage Menu',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showItemDialog(context, controller),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('New item',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF252525),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF252525)),
                  );
                }

                if (controller.menuItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          "You haven't added any items yet.",
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                final grouped = <String, List<Map<String, dynamic>>>{};
                for (var item in controller.menuItems) {
                  final cat = item['category'] as String? ?? 'Others';
                  grouped.putIfAbsent(cat, () => []).add(item);
                }

                return RefreshIndicator(
                  onRefresh: controller.fetchMenuItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, catIndex) {
                      final category = grouped.keys.elementAt(catIndex);
                      final items = grouped[category]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 10),
                            child: Text(
                              category,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildItemCard(context, item, controller),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    Map<String, dynamic> item,
    MerchantMenuController controller,
  ) {
    final id = item['id'] as String;
    final name = item['name'].toString();
    final price = (item['price'] as num).toDouble();
    final stock = item['stock'] as int;
    final isAvailable = item['isavailable'] as bool? ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isAvailable ? Colors.black : Colors.grey[500],
                    decoration:
                        isAvailable ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RM ${price.toStringAsFixed(2)} · Stock: $stock',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            activeColor: const Color(0xFF252525),
            onChanged: (v) => controller.toggleAvailability(id, v),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: Colors.grey[700],
            onPressed: () =>
                _showItemDialog(context, controller, existingItem: item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red[400],
            onPressed: () => _confirmDelete(context, controller, id, name),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MerchantMenuController controller,
    String itemId,
    String name,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Item', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Remove "$name" from your menu? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteItem(itemId, name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showItemDialog(
    BuildContext context,
    MerchantMenuController controller, {
    Map<String, dynamic>? existingItem,
  }) {
    final isEdit = existingItem != null;

    final nameController =
        TextEditingController(text: isEdit ? existingItem['name'] : '');
    final priceController = TextEditingController(
        text: isEdit ? (existingItem['price'] as num).toString() : '');
    final stockController = TextEditingController(
        text: isEdit ? existingItem['stock'].toString() : '');
    String selectedCategory =
        isEdit ? (existingItem['category'] ?? _categories.first) : _categories.first;
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'Edit Item' : 'Add New Item',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      hintText: 'e.g. Fried Chicken',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price (RM)',
                      hintText: 'e.g. 5.50',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                  TextFormField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Stock',
                      hintText: 'e.g. 50',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: _categories
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
                if (isEdit) {
                  controller.updateItem(
                    itemId: existingItem['id'] as String,
                    name: nameController.text,
                    price: double.parse(priceController.text.trim()),
                    category: selectedCategory,
                    stock: int.parse(stockController.text.trim()),
                  );
                } else {
                  controller.addItem(
                    name: nameController.text,
                    price: double.parse(priceController.text.trim()),
                    category: selectedCategory,
                    stock: int.parse(stockController.text.trim()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF252525),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEdit ? 'Save Changes' : 'Add Item',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}