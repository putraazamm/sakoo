// lib/controllers/merchant_menu_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'merchant_dashboard_controller.dart';

/// Handles full CRUD for this merchant's items in the `item` table.
/// Any insert/update/delete here is what the kiosk side picks up
/// automatically via its Realtime subscription in KioskController.
class MerchantMenuController extends GetxController {
  final _supabase = Supabase.instance.client;

  var menuItems = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  String? get _merchantId =>
      Get.find<MerchantDashboardController>().merchantData['id'] as String?;

  bool _hasFetchedOnce = false;

  @override
  void onInit() {
    super.onInit();

    final dashboard = Get.find<MerchantDashboardController>();
    _tryFetch(dashboard);
    ever(dashboard.merchantData, (_) => _tryFetch(dashboard));
  }

  void _tryFetch(MerchantDashboardController dashboard) {
    if (dashboard.merchantData['id'] == null) return;
    if (_hasFetchedOnce) return; // avoid re-fetching on every unrelated change
    _hasFetchedOnce = true;
    fetchMenuItems();
  }

  Future<void> fetchMenuItems() async {
    try {
      isLoading.value = true;
      final merchantId = _merchantId;
      if (merchantId == null) return;

      final response = await _supabase
          .from('item')
          .select()
          .eq('merchantid', merchantId)
          .order('category')
          .order('name');

      menuItems.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('MerchantMenuController.fetchMenuItems: $e');
      Get.snackbar(
        'Error',
        'Failed to load your menu.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addItem({
    required String name,
    required double price,
    required String category,
    required int stock,
  }) async {
    final merchantId = _merchantId;
    if (merchantId == null) return;

    try {
      await _supabase.from('item').insert({
        'merchantid': merchantId,
        'name': name.trim(),
        'price': price,
        'category': category.trim(),
        'stock': stock,
        'isavailable': true,
      });

      Get.snackbar(
        'Item Added',
        '$name has been added to your menu.',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      await fetchMenuItems();
    } catch (e) {
      debugPrint('MerchantMenuController.addItem: $e');
      Get.snackbar(
        'Error',
        'Failed to add item: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> updateItem({
    required String itemId,
    required String name,
    required double price,
    required String category,
    required int stock,
  }) async {
    try {
      await _supabase.from('item').update({
        'name': name.trim(),
        'price': price,
        'category': category.trim(),
        'stock': stock,
      }).eq('id', itemId);

      Get.snackbar(
        'Item Updated',
        '$name has been updated.',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      await fetchMenuItems();
    } catch (e) {
      debugPrint('MerchantMenuController.updateItem: $e');
      Get.snackbar(
        'Error',
        'Failed to update item: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// Quick on/off switch — hides the item from the kiosk/order menu
  /// immediately without deleting its row (keeps price/stock history intact).
  Future<void> toggleAvailability(String itemId, bool newValue) async {
    try {
      await _supabase
          .from('item')
          .update({'isavailable': newValue}).eq('id', itemId);

      final index = menuItems.indexWhere((e) => e['id'] == itemId);
      if (index != -1) {
        menuItems[index] = {...menuItems[index], 'isavailable': newValue};
        menuItems.refresh();
      }
    } catch (e) {
      debugPrint('MerchantMenuController.toggleAvailability: $e');
      Get.snackbar(
        'Error',
        'Failed to update availability: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteItem(String itemId, String name) async {
    try {
      await _supabase.from('item').delete().eq('id', itemId);

      Get.snackbar(
        'Item Removed',
        '$name has been removed from your menu.',
        backgroundColor: Colors.grey.withOpacity(0.15),
        colorText: Colors.black87,
      );

      await fetchMenuItems();
    } catch (e) {
      debugPrint('MerchantMenuController.deleteItem: $e');
      Get.snackbar(
        'Error',
        'Failed to remove item: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}