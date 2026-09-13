// lib/screens/parent/child_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
// import 'package:intl/date_symbols.dart';
import '../../controllers/child_detail_controller.dart';
import '../../models/transaction_model.dart';
import '../../models/goal_model.dart';
// import '../../models/child_model.dart';

class ChildDetailScreen extends StatelessWidget {
  const ChildDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Card Management",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "You can manage your child's card here.",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Everything below scrolls together as one page, EXCEPT the
              // transaction/weekly summary box further down, which has its
              // own independent scroll (see SizedBox -> _RecentTransactionsTab
              // / _WeeklySummaryTab).
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Obx(() {
                          final child = controller.childData.value;
                          if (child == null)
                            return const CircularProgressIndicator();

                          bool isLinked = child.cardId.trim().isNotEmpty;

                          return Column(
                            children: [
                              // Kad UI — wrapped with extra breathing room so
                              // the edit badge (positioned at top:-10/right:-10
                              // of the Stack, outside the card's own bounds)
                              // has room to render fully instead of being
                              // clipped by the screen edge or scroll view.
                              Container(
                                padding: const EdgeInsets.all(12),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 280,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF252525),
                                            Color(0xFF4A4A4A),
                                            Color(0xFF1E1E1E),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: SvgPicture.asset(
                                              'lib/assets/images/sakoo-logo-welcome-screen.svg', // logo sakoo with gray black gradient
                                              height: 20,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Colors.white,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            child.childNickname.isNotEmpty
                                                ? child.childNickname
                                                : child.childName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                isLinked
                                                    ? child.cardId
                                                    : 'Not Linked',
                                                style: TextStyle(
                                                  color: isLinked
                                                      ? Colors.grey[400]
                                                      : Colors.white,
                                                  fontSize: 12,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              Icon(
                                                Icons.visibility_outlined,
                                                color: Colors.grey[400],
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'RM ${child.childBalance.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isLinked && child.isActive
                                                      ? const Color(0xFF1E3A2F)
                                                      : const Color(0xFF6B6A1A),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  isLinked && child.isActive
                                                      ? 'ACTIVE'
                                                      : 'NOT ACTIVE',
                                                  style: TextStyle(
                                                    color:
                                                        isLinked &&
                                                            child.isActive
                                                        ? const Color(
                                                            0xFF6ED7A4,
                                                          )
                                                        : Colors.yellow[300],
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Edit button at the edge of the card
                                    Positioned(
                                      top: -10,
                                      right: -10,
                                      child: GestureDetector(
                                        onTap: () => controller
                                            .showEditChildSheet(context, child),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Teks Status & Butang Link NFC
                              if (!isLinked) ...[
                                Text(
                                  '${child.childNickname} is not linked to Sakoo card yet.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: controller.isScanning.value
                                      ? null
                                      : () => controller.linkNfcCard(),
                                  icon: const Icon(
                                    Icons.link,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  label: Text(
                                    controller.isScanning.value
                                        ? 'Scanning...'
                                        : 'Link',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // maybe change to get.snackbar since this text just appear when it is first time the card linked.
                              ],
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
                            onPressed: () => controller.showTransactionSheet(
                              context,
                              isTopUp: true,
                            ),
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add Funds',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B2B2B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => controller.showTransactionSheet(
                              context,
                              isTopUp: false,
                            ),
                            icon: const Icon(
                              Icons.arrow_outward,
                              size: 18,
                              color: Colors.black87,
                            ),
                            label: const Text(
                              'Withdraw',
                              style: TextStyle(color: Colors.black87),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 4. Tabs (Recent Transactions, Weekly Summary, Savings Goals)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Obx(
                          () => Row(
                            children: [
                              GestureDetector(
                                onTap: () => controller.selectedTab.value = 0,
                                child: Text(
                                  'Recent Transactions',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        controller.selectedTab.value == 0
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: controller.selectedTab.value == 0
                                        ? Colors.black87
                                        : Colors.grey[500],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => controller.selectedTab.value = 1,
                                child: Text(
                                  'Weekly Summary',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        controller.selectedTab.value == 1
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: controller.selectedTab.value == 1
                                        ? Colors.black87
                                        : Colors.grey[500],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => controller.selectedTab.value = 2,
                                child: Text(
                                  'Savings Goals',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        controller.selectedTab.value == 2
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: controller.selectedTab.value == 2
                                        ? Colors.black87
                                        : Colors.grey[500],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 5. Tab content box with its OWN independent scroll,
                      // separate from the page-level SingleChildScrollView above.
                      SizedBox(
                        height: 420,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Obx(() {
                            if (controller.selectedTab.value == 0) {
                              return _RecentTransactionsTab(
                                controller: controller,
                              );
                            } else if (controller.selectedTab.value == 1) {
                              return _WeeklySummaryTab(controller: controller);
                            } else {
                              return _SavingsGoalsTab(controller: controller);
                            }
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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

// ---------------------------------------------------------------------------
// Recent Transactions tab
// ---------------------------------------------------------------------------
class _RecentTransactionsTab extends StatelessWidget {
  final ChildDetailController controller;

  const _RecentTransactionsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingTransactions.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      final transactions = controller.childTransactions;

      if (transactions.isEmpty) {
        return Center(
          child: Text(
            'No recent transaction',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchChildTransactions,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return _TransactionTile(transaction: tx);
          },
        ),
      );
    });
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  // Classify a transaction so the UI can pick the right icon/color/sign.
  _TxKind get _kind {
    final category = transaction.category.toLowerCase();
    if (category.contains('top-up') || category.contains('top up')) {
      return _TxKind.topUp;
    } else if (category.contains('withdraw')) {
      return _TxKind.withdraw;
    }
    return _TxKind.spend;
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    final formattedDate = DateFormat(
      'dd MMM, hh:mm a',
    ).format(transaction.createdAt);

    IconData icon;
    Color iconColor;
    Color iconBg;
    String amountPrefix;
    Color amountColor;

    switch (kind) {
      case _TxKind.topUp:
        icon = Icons.add_circle_outline;
        iconColor = const Color(0xFF2E7D32);
        iconBg = const Color(0xFFE5F5E8);
        amountPrefix = '+';
        amountColor = const Color(0xFF2E7D32);
        break;
      case _TxKind.withdraw:
        icon = Icons.arrow_outward;
        iconColor = const Color(0xFFB45309);
        iconBg = const Color(0xFFFCEFD8);
        amountPrefix = '-';
        amountColor = const Color(0xFFB45309);
        break;
      case _TxKind.spend:
        icon = Icons.store_outlined;
        iconColor = const Color(0xFF1D4ED8);
        iconBg = const Color(0xFFE3EBFD);
        amountPrefix = '-';
        amountColor = Colors.black87;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconBg,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.category,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix RM ${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formattedDate,
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TxKind { topUp, withdraw, spend }

// ---------------------------------------------------------------------------
// Weekly Summary tab
// ---------------------------------------------------------------------------
class _WeeklySummaryTab extends StatelessWidget {
  final ChildDetailController controller;

  const _WeeklySummaryTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingTransactions.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      final days = controller.weeklySummary;

      if (days.isEmpty ||
          (controller.weeklyTotalSpend == 0 &&
              controller.weeklyTotalTopUp == 0 &&
              controller.weeklyTotalWithdraw == 0)) {
        return Center(
          child: Text(
            'No weekly summary available.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        );
      }

      final maxValue = days.fold<double>(0.0, (max, day) {
        final total =
            (day['spend'] as double) +
            (day['topUp'] as double) +
            (day['withdraw'] as double);
        return total > max ? total : max;
      });

      return RefreshIndicator(
        onRefresh: controller.fetchChildTransactions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Totals row
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: 'Spent',
                    amount: controller.weeklyTotalSpend,
                    color: Colors.black87,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: 'Added',
                    amount: controller.weeklyTotalTopUp,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: 'Withdrawn',
                    amount: controller.weeklyTotalWithdraw,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Simple bar chart, one bar per day (last 7 days)
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((day) {
                  final date = day['date'] as DateTime;
                  final spend = day['spend'] as double;
                  final topUp = day['topUp'] as double;
                  final withdraw = day['withdraw'] as double;
                  final total = spend + topUp + withdraw;

                  final barHeight = maxValue > 0
                      ? (total / maxValue) * 100
                      : 0.0;
                  final isToday = DateTime.now().difference(date).inDays == 0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (total > 0)
                            Text(
                              total >= 1000
                                  ? '${(total / 1000).toStringAsFixed(1)}k'
                                  : total.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight < 4 ? 4 : barHeight,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFF2B2B2B)
                                  : Colors.grey[350],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('E').format(date).substring(0, 1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isToday
                                  ? Colors.black87
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Day-by-day breakdown list
            ...days.reversed.map((day) {
              final date = day['date'] as DateTime;
              final spend = day['spend'] as double;
              final topUp = day['topUp'] as double;
              final withdraw = day['withdraw'] as double;

              if (spend == 0 && topUp == 0 && withdraw == 0) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        DateFormat('dd MMM').format(date),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        children: [
                          if (spend > 0)
                            Text(
                              'Spent RM ${spend.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          if (topUp > 0)
                            Text(
                              '+RM ${topUp.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          if (withdraw > 0)
                            Text(
                              '-RM ${withdraw.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB45309),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Savings Goals tab
// ---------------------------------------------------------------------------
class _SavingsGoalsTab extends StatelessWidget {
  final ChildDetailController controller;

  const _SavingsGoalsTab({required this.controller});

  static const _iconChoices = ['🎯', '🚲', '🎮', '📱', '👟', '⚽', '🎸', '✈️'];

  void _showNewGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    String selectedIcon = _iconChoices.first;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New Savings Goal',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: _iconChoices.map((icon) {
                    final selected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF252525)
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'What are you saving for?',
                    hintText: 'e.g. New Bicycle',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Target Amount (RM)',
                    hintText: 'e.g. 150',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final target =
                    double.tryParse(targetController.text.trim()) ?? 0;
                controller.createGoal(
                  titleController.text,
                  target,
                  icon: selectedIcon,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF252525),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Goal',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContributeDialog(BuildContext context, GoalModel goal) {
    final amountController = TextEditingController();
    final childBalance = controller.childData.value?.childBalance ?? 0.0;

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Save towards "${goal.goalTitle}"',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card balance: RM ${childBalance.toStringAsFixed(2)}  ·  Remaining to goal: RM ${goal.remainingAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount (RM)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              controller.contributeToGoal(goal.goalId, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF252525),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingGoals.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      final goals = controller.goalsList;

      return RefreshIndicator(
        onRefresh: controller.fetchGoals,
        child: ListView(
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showNewGoalDialog(context),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'New Goal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF252525),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
              ),
            ),
            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No savings goals yet.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              )
            else
              ...goals.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GoalCard(
                    goal: g,
                    onContribute: () => _showContributeDialog(context, g),
                    onCashOut: () => controller.cashOutGoal(g.goalId),
                    onDelete: () =>
                        controller.deleteGoal(g.goalId, g.collectedAmount),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onContribute;
  final VoidCallback onCashOut;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onContribute,
    required this.onCashOut,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final canDelete = goal.collectedAmount == 0;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Text(goal.icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.goalTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: goal.isCompleted ? Colors.green : const Color(0xFF252525),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RM ${goal.collectedAmount.toStringAsFixed(2)} / RM ${goal.targetAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (goal.isCompleted)
                ElevatedButton(
                  onPressed: onCashOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cash Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: onContribute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252525),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
