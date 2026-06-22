import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'merchant_dashboard_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/merchant/merchant_checkout_page.dart';

class MerchantNewOrderController extends GetxController {
  final _supabase = Supabase.instance.client;

  var menuItems = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var cart = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMenuItems();
  }

  Future<void> fetchMenuItems() async {
    try {
      isLoading.value = true;
      final merchantId =
          Get.find<MerchantDashboardController>().merchantData['id'] as String?;

      if (merchantId == null) return;

      final response = await _supabase
          .from('item')
          .select()
          .eq('merchantid', merchantId)
          .eq('isavailable', true)
          .order('category')
          .order('name');

      menuItems.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Error fetching menu items: $e');
      Get.snackbar(
        "Error",
        "Failed to load items list.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // add new item to Supabase
  Future<void> addItem({
    required String name,
    required double price,
    required String category,
    required int stock,
  }) async {
    try {
      final merchantId =
          Get.find<MerchantDashboardController>().merchantData['id'] as String?;

      if (merchantId == null) return;

      await _supabase.from('item').insert({
        'merchantid': merchantId,
        'name': name.trim(),
        'price': price,
        'category': category.trim(),
        'stock': stock,
        'isavailable': true,
      });

      Get.snackbar(
        'Item added',
        '$name has been added to your list/menu.',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      await fetchMenuItems();
    } catch (e) {
      debugPrint('Error adding item: $e');
      Get.snackbar(
        'Error',
        'Failed to add item: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // cart logic (using uuid string as key)
  double get totalPrice {
    double total = 0.0;
    for (var item in menuItems) {
      final id = item['id'] as String;
      final price = (item['price'] as num).toDouble();
      final qty = cart[id] ?? 0;
      total += price * qty;
    }
    return total;
  }

  // Fungsi Tambah (+)
  void increment(String id) {
    final item = menuItems.firstWhereOrNull((e) => e['id'] == id);
    if (item == null) return;
    final stock = item['stock'] as int;
    final currentQty = cart[id] ?? 0;
    if (currentQty >= stock) {
      Get.snackbar(
        "Out of stock",
        "No more stock available for this item.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    cart[id] = currentQty + 1;
  }

  // Fungsi Tolak (-)
  void decrement(String id) {
    final currentQty = cart[id] ?? 0;
    if (currentQty > 0) {
      cart[id] = currentQty - 1;
    }
  }

  void clearCart() {
    cart.clear();
  }

  // Fungsi apabila butang 'Next >' ditekan
  void proceedToPayment() {
    if (totalPrice == 0) {
      Get.snackbar("No order", "Please at least add one item.");
      return;
    }

    final List<Map<String, dynamic>> orderedItems = [];
    for (var item in menuItems) {
      final id = item['id'] as String;
      final qty = cart[id] ?? 0;
      if (qty > 0) {
        orderedItems.add({
          'id': id,
          'name': item['name'],
          'price': item['price'],
          'quantity': qty,
          'subtotal': (item['price'] as double) * qty,
          'category': item['category'] ?? 'Others',
        });
      }
    }

    final String? merchantId =
        Get.find<MerchantDashboardController>().merchantData['id'] as String?;

    Get.to(
      () => MerchantCheckoutScreen(),
      arguments: {
        'items': orderedItems,
        'total': totalPrice,
        'merchantid': merchantId,
      },
    );
  }
}
