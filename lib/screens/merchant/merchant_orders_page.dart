// lib/screens/merchant/merchant_orders_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/merchant_orders_controller.dart';

class MerchantOrdersPage extends StatelessWidget {
  const MerchantOrdersPage({Key? key}) : super(key: key);

  static const _statusLabels = {
    'pending': 'Pending',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  static const _statusColors = {
    'pending': Colors.orange,
    'completed': Colors.green,
    'cancelled': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MerchantOrdersController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Orders',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF252525)),
                  );
                }

                if (controller.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No orders yet.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                final pending = controller.pendingOrders;
                final completed = controller.completedOrders;
                final cancelled = controller.cancelledOrders;

                return RefreshIndicator(
                  onRefresh: controller.fetchOrders,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      if (pending.isNotEmpty) ...[
                        const Text(
                          'Pending',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        ...pending.map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildOrderCard(context, o, controller),
                            )),
                        const SizedBox(height: 12),
                      ],
                      if (completed.isNotEmpty) ...[
                        Text(
                          'Completed',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 10),
                        ...completed.map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildOrderCard(context, o, controller),
                            )),
                        const SizedBox(height: 12),
                      ],
                      if (cancelled.isNotEmpty) ...[
                        Text(
                          'Cancelled',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 10),
                        ...cancelled.map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildOrderCard(context, o, controller),
                            )),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
    MerchantOrdersController controller,
  ) {
    final id = order['id'] as String;
    final status = (order['status'] ?? 'pending') as String;
    final amount = (order['amount'] as num).toDouble();
    final childName = order['child'] != null
        ? (order['child']['childName'] ?? 'Student')
        : 'Student';
    final createdAt = DateTime.tryParse(order['createdAt']?.toString() ?? '');
    final dateTimeLabel = createdAt != null
        ? DateFormat('d MMM yyyy, HH:mm').format(createdAt.toLocal())
        : '';

    final items = (order['orderDetails'] is List)
        ? List<Map<String, dynamic>>.from(order['orderDetails'])
        : <Map<String, dynamic>>[];

    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFF3E0) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  childName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isPending ? Colors.black : Colors.grey[500],
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_statusColors[status] ?? Colors.grey)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabels[status] ?? status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColors[status] ?? Colors.grey[700],
                      ),
                    ),
                  ),
                  if (isPending)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'cancel') {
                          _confirmCancel(context, controller, id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'cancel',
                          child: Text('Cancel Order',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isNotEmpty)
            Text(
              items.map((i) => '${i['quantity']}x ${i['name']}').join(', '),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RM ${amount.toStringAsFixed(2)}${dateTimeLabel.isNotEmpty ? ' · $dateTimeLabel' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              if (isPending)
                ElevatedButton(
                  onPressed: () => controller.completeOrder(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252525),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Complete',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCancel(
    BuildContext context,
    MerchantOrdersController controller,
    String orderId,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Order',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.cancelOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}