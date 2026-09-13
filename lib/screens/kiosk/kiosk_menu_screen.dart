// lib/screens/kiosk/kiosk_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/kiosk_controller.dart';

class KioskMenuScreen extends StatelessWidget {
  const KioskMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KioskController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            _Header(controller: controller),

            // ── Category tabs ───────────────────────────────────
            _CategoryTabs(controller: controller),

            // ── Items ───────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoadingMenu.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF252525)),
                  );
                }
                final items = controller.filteredItems;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      controller.t(
                          'No items available.', 'Tiada item tersedia.'),
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 15),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) =>
                      _ItemCard(item: items[i], controller: controller),
                );
              }),
            ),

            // ── Bottom bar ──────────────────────────────────────
            _BottomBar(controller: controller),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final KioskController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              Get.back();
              controller.cart.clear();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: Colors.black),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.t(
                          'Please order your food',
                          'Sila pilih makanan anda'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.t(
                          'Hi, ${controller.childName.value}!',
                          'Hai, ${controller.childName.value}!'),
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                )),
          ),
        ],
      ),
    );
  }
}

// ── Category tabs ─────────────────────────────────────────────────────
class _CategoryTabs extends StatelessWidget {
  final KioskController controller;
  const _CategoryTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cats = controller.categories;
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cats.map((cat) {
              final isSelected = controller.selectedCat.value == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.selectedCat.value = cat,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF252525)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}

// ── Item card ─────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final KioskController controller;

  const _ItemCard({required this.item, required this.controller});

  // Category → color + icon
  Color _bgColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'food & drink':
      case 'food':
        return const Color(0xFFFFEECC);
      case 'beverage':
      case 'drink':
        return const Color(0xFFCCEEFF);
      case 'snack':
        return const Color(0xFFFFDDCC);
      default:
        return const Color(0xFFEEEEEE);
    }
  }

  IconData _icon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food & drink':
      case 'food':
        return Icons.lunch_dining_rounded;
      case 'beverage':
      case 'drink':
        return Icons.local_drink_rounded;
      case 'snack':
        return Icons.bakery_dining_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  Color _iconColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'food & drink':
      case 'food':
        return const Color(0xFFE5820A);
      case 'beverage':
      case 'drink':
        return const Color(0xFF0A7CE5);
      case 'snack':
        return const Color(0xFFE54E0A);
      default:
        return const Color(0xFF555555);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id       = item['id'] as String;
    final name     = item['name']?.toString() ?? '';
    final price    = (item['price'] as num).toDouble();
    final category = item['category']?.toString() ?? 'Others';
    final stock    = item['stock'] as int;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / icon area
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: _bgColor(category),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Icon(_icon(category),
                  size: 52, color: _iconColor(category)),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'RM ${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Stepper
                Obx(() {
                  final qty       = controller.cart[id] ?? 0;
                  final remaining = stock - qty;
                  return Row(
                    children: [
                      // − button
                      _StepBtn(
                        icon: Icons.remove,
                        onTap: () => controller.decrement(id),
                        enabled: qty > 0,
                      ),
                      // quantity
                      Expanded(
                        child: Text(
                          qty.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // + button
                      _StepBtn(
                        icon: Icons.add,
                        onTap: () => controller.increment(id),
                        enabled: remaining > 0,
                      ),
                    ],
                  );
                }),

                // Stock indicator
                Obx(() {
                  final qty       = controller.cart[id] ?? 0;
                  final remaining = stock - qty;
                  if (remaining > 10) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      remaining == 0
                          ? controller.t('Sold out', 'Habis')
                          : '${remaining} ${controller.t('left', 'baki')}',
                      style: TextStyle(
                        fontSize: 10,
                        color: remaining == 0
                            ? Colors.red
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stepper button ───────────────────────────────────────────────────
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepBtn(
      {required this.icon,
      required this.onTap,
      this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF252525)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white : Colors.grey[400],
        ),
      ),
    );
  }
}

// ── Bottom bar ───────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final KioskController controller;
  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final balance   = controller.childBalance.value;
      final total     = controller.totalPrice;
      final remaining = controller.remainingBalance;
      final isLow     = remaining < 0;

      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          children: [
            // Balance rows
            _BalanceRow(
              label: controller.t('Account Balance', 'Baki Akaun'),
              value: 'RM ${balance.toStringAsFixed(2)}',
              valueColor: Colors.black,
            ),
            const SizedBox(height: 6),
            _BalanceRow(
              label: controller.t('Total', 'Jumlah'),
              value: 'RM ${total.toStringAsFixed(2)}',
              valueColor: Colors.black,
              isBold: true,
            ),
            const Divider(height: 16, thickness: 1),
            _BalanceRow(
              label: controller.t(
                  'Balance after payment', 'Baki selepas pembayaran'),
              value: 'RM ${remaining.toStringAsFixed(2)}',
              valueColor: isLow ? Colors.red : Colors.green[700]!,
              isBold: true,
            ),

            const SizedBox(height: 14),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: (controller.cartIsEmpty || isLow ||
                        controller.isProcessing.value)
                    ? null
                    : () => controller.pay(context),
                icon: controller.isProcessing.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.contactless_rounded,
                        color: Colors.white, size: 24),
                label: Text(
                  controller.isProcessing.value
                      ? controller.t('Processing...', 'Memproses...')
                      : controller.t('Pay', 'Bayar'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (controller.cartIsEmpty || isLow)
                          ? Colors.grey[300]
                          : const Color(0xFF252525),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}