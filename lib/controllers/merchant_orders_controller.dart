// lib/controllers/merchant_orders_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'merchant_dashboard_controller.dart';

/// Order status lifecycle: pending -> completed, or pending -> cancelled.
class MerchantOrdersController extends GetxController {
  final _supabase = Supabase.instance.client;

  var orders = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  RealtimeChannel? _orderChannel;
  bool _hasFetchedOnce = false;

  String? get _merchantId =>
      Get.find<MerchantDashboardController>().merchantData['id'] as String?;

  static const List<String> _nonOrderCategories = ['Top-Up', 'Withdrawal'];

  @override
  void onInit() {
    super.onInit();

    final dashboard = Get.find<MerchantDashboardController>();
    _tryInit(dashboard);
    ever(dashboard.merchantData, (_) => _tryInit(dashboard));
  }

  void _tryInit(MerchantDashboardController dashboard) {
    if (dashboard.merchantData['id'] == null) return;
    if (_hasFetchedOnce) return;
    _hasFetchedOnce = true;
    fetchOrders();
    _subscribeToOrderChanges();
  }

  @override
  void onClose() {
    if (_orderChannel != null) {
      _supabase.removeChannel(_orderChannel!);
    }
    super.onClose();
  }

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;

      final merchantId = _merchantId;
      if (merchantId == null) return; // isLoading still reset by `finally` below

      final res = await _supabase
          .from('transaction')
          .select('*, child(childName)')
          .eq('merchantId', merchantId)
          .not('category', 'in', '(${_nonOrderCategories.join(',')})')
          .order('createdAt', ascending: false)
          .limit(100);

      orders.assignAll(List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('MerchantOrdersController.fetchOrders: $e');
      Get.snackbar(
        'Error',
        'Failed to load orders.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToOrderChanges() {
    final merchantId = _merchantId;
    if (merchantId == null) return;

    _orderChannel = _supabase
        .channel('merchant-order-changes-$merchantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transaction',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'merchantId',
            value: merchantId,
          ),
          callback: (payload) => fetchOrders(),
        )
        .subscribe();
  }

  List<Map<String, dynamic>> get pendingOrders =>
      orders.where((o) => (o['status'] ?? 'pending') == 'pending').toList();

  List<Map<String, dynamic>> get completedOrders =>
      orders.where((o) => o['status'] == 'completed').toList();

  List<Map<String, dynamic>> get cancelledOrders =>
      orders.where((o) => o['status'] == 'cancelled').toList();

  Future<void> _setStatus(String orderId, String status) async {
    try {
      await _supabase.from('transaction').update({'status': status}).eq('id', orderId);

      final index = orders.indexWhere((o) => o['id'] == orderId);
      if (index != -1) {
        orders[index] = {...orders[index], 'status': status};
        orders.refresh();
      }
    } catch (e) {
      debugPrint('MerchantOrdersController._setStatus: $e');
      Get.snackbar(
        'Error',
        'Failed to update order: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> completeOrder(String orderId) => _setStatus(orderId, 'completed');

  Future<void> cancelOrder(String orderId) => _setStatus(orderId, 'cancelled');
}