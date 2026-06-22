// lib/screens/parent/all_transactions_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/parent_dashboard_controller.dart';
import '../../models/transaction_model.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({Key? key}) : super(key: key);

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  final controller = Get.find<ParentDashboardController>();

  // Filter & sort state
  String _selectedType = 'All';
  bool _newestFirst = true;

  final List<String> _types = [
    'All',
    'Top-Up',
    'Withdrawal',
    'Food & Drink',
    'Beverage',
    'Snack',
    'Others',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAllTransactions();
    });
  }

  List<TransactionModel> get _filtered {
    List<TransactionModel> list = List.from(controller.allTransactions);

    // Filter by type
    if (_selectedType != 'All') {
      list = list.where((t) => t.category == _selectedType).toList();
    }

    // Sort by date
    list.sort(
      (a, b) => _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );

    return list;
  }

  // Group transactions by date label (Today / Yesterday / dd MMM yyyy)
  Map<String, List<TransactionModel>> get _grouped {
    final map = <String, List<TransactionModel>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in _filtered) {
      final txDay = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      String label;
      if (txDay == today) {
        label = 'Today';
      } else if (txDay == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('dd MMM yyyy').format(tx.createdAt);
      }
      map.putIfAbsent(label, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'All Transactions',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        // Sort toggle button
        actions: [
          IconButton(
            onPressed: () => setState(() => _newestFirst = !_newestFirst),
            tooltip: _newestFirst ? 'Newest first' : 'Oldest first',
            icon: Icon(
              _newestFirst
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Filter chips ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF252525)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _iconFor(type),
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // --- Transaction list ---
          Expanded(
            child: Obx(() {
              if (controller.isLoadingAll.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF252525)),
                );
              }

              final grouped = _grouped;

              if (grouped.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions found.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFF252525),
                onRefresh: () => controller.fetchAllTransactions(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, groupIndex) {
                    final dateLabel = grouped.keys.elementAt(groupIndex);
                    final txList = grouped[dateLabel]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        // Transaction cards for this date
                        ...txList.map((tx) => _buildTxCard(tx)),
                      ],
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTxCard(TransactionModel tx) {
    final isTopUp = tx.category == 'Top-Up';
    final isWithdrawal = tx.category == 'Withdrawal';
    final isPurchase = tx.category == 'Food & Drink';

    Color amountColor;
    Color iconBg;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (isTopUp) {
      amountColor = Colors.green[700]!;
      iconBg = Colors.green[50]!;
      iconColor = Colors.green[600]!;
      icon = Icons.add_circle_outline_rounded;
      title = 'Top-Up';
      subtitle = tx.childName.isNotEmpty
          ? 'To ${tx.childName}'
          : 'Wallet Top-Up';
    } else if (isWithdrawal) {
      amountColor = Colors.orange[700]!;
      iconBg = Colors.orange[50]!;
      iconColor = Colors.orange[600]!;
      icon = Icons.remove_circle_outline_rounded;
      title = 'Withdrawal';
      subtitle = tx.childName.isNotEmpty
          ? 'From ${tx.childName}'
          : 'Wallet Withdrawal';
    } else {
      // Food & Drink / Purchase
      amountColor = Colors.red[600]!;
      iconBg = Colors.blue[50]!;
      iconColor = Colors.blue[400]!;
      icon = Icons.storefront_rounded;
      title = tx.merchantName.isNotEmpty ? tx.merchantName : 'Purchase';
      subtitle = tx.childName.isNotEmpty
          ? '${tx.childName} • ${tx.category}'
          : tx.category;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPurchase || isWithdrawal ? '-' : '+'}RM ${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('hh:mm a').format(tx.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'Top-Up':
        return Icons.add_circle_outline_rounded;
      case 'Withdrawal':
        return Icons.remove_circle_outline_rounded;
      case 'Food & Drink':
        return Icons.storefront_rounded;
      case 'Beverage':
        return Icons.emoji_food_beverage;
      case 'Snack':
        return Icons.storefront_rounded;
      case 'Others':
        return Icons.miscellaneous_services;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
