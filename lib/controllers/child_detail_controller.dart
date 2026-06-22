// lib/controllers/child_detail_controller.dart

// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:action_slider/action_slider.dart';

import '../models/child_model.dart';
import '../models/transaction_model.dart';
import '../screens/parent/widgets/edit_child_sheet.dart';
import 'parent_dashboard_controller.dart';

class ChildDetailController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  var selectedTab = 0.obs;

  var childData = Rx<ChildModel?>(null);
  var isScanning = false.obs;

  var deactivationSlidesRemaining = 3.obs;
  var isDeactivatedMode = false.obs;

  // --- Edit sheet: Scheduled Auto Top-Up draft state (only used while the
  // edit bottom sheet is open; committed to Supabase on Save) ---
  var editAutoTopUpEnabled = false.obs;
  var editAutoTopUpFrequency = 'weekly'.obs; // 'daily' | 'weekly' | 'monthly'
  var editAutoTopUpDay = 1.obs; // ISO weekday (1-7) or day-of-month (1-28)

  // --- Transaction / Weekly Summary state ---
  var isLoadingTransactions = true.obs;
  var childTransactions = <TransactionModel>[].obs;

  // Weekly summary: list of 7 days (oldest -> newest), each with topUp/spend/withdraw totals
  var weeklySummary = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    childData.value = Get.arguments as ChildModel;
    fetchChildTransactions();
  }

  // Fetch all transactions belonging to this child (top-ups, withdrawals, purchases)
  Future<void> fetchChildTransactions() async {
    final child = childData.value;
    if (child == null) return;

    try {
      isLoadingTransactions.value = true;

      final List<dynamic> data = await _supabase
          .from('transaction')
          .select('*, child(childName)')
          .eq('childId', child.childId)
          .order('createdAt', ascending: false)
          .limit(50);

      childTransactions.assignAll(
        data.map((e) => TransactionModel.fromJson(e)).toList(),
      );

      _buildWeeklySummary();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load transactions: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
      );
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  // Build a 7-day rolling summary (oldest day first) from childTransactions.
  void _buildWeeklySummary() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Map<String, dynamic>> summary = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return {
        'date': day,
        'topUp': 0.0,
        'withdraw': 0.0,
        'spend': 0.0,
      };
    });

    final startRange = today.subtract(const Duration(days: 6));

    for (final tx in childTransactions) {
      final txDay = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );

      if (txDay.isBefore(startRange) || txDay.isAfter(today)) continue;

      final dayIndex = txDay.difference(startRange).inDays;
      if (dayIndex < 0 || dayIndex >= summary.length) continue;

      final category = tx.category.toLowerCase();
      if (category.contains('top-up') || category.contains('top up')) {
        summary[dayIndex]['topUp'] =
            (summary[dayIndex]['topUp'] as double) + tx.amount;
      } else if (category.contains('withdraw')) {
        summary[dayIndex]['withdraw'] =
            (summary[dayIndex]['withdraw'] as double) + tx.amount;
      } else {
        summary[dayIndex]['spend'] =
            (summary[dayIndex]['spend'] as double) + tx.amount;
      }
    }

    weeklySummary.assignAll(summary);
  }

  // Totals across the visible 7-day window, used for the summary header.
  double get weeklyTotalSpend => weeklySummary.fold<double>(
        0.0,
        (sum, day) => sum + (day['spend'] as double),
      );

  double get weeklyTotalTopUp => weeklySummary.fold<double>(
        0.0,
        (sum, day) => sum + (day['topUp'] as double),
      );

  double get weeklyTotalWithdraw => weeklySummary.fold<double>(
        0.0,
        (sum, day) => sum + (day['withdraw'] as double),
      );

  Future<void> linkNfcCard() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        Get.snackbar(
          'NFC Error',
          'Your device is not support NFC or NFC is not turned on.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      isScanning.value = true;

      // 2. Mula sesi imbasan (Sangat ringkas berbanding nfc_manager)
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 15),
        iosAlertMessage:
            "Please tap your Sakoo NFC card at the back of your device.",
      );

      // 3. Ekstrak UID (Unique ID) dari kad NFC
      // flutter_nfc_kit akan terus berikan ID dalam format Hex String
      String newCardId = tag.id;

      if (newCardId.isEmpty) {
        await FlutterNfcKit.finish(iosErrorMessage: "Failed to read card ID.");
        isScanning.value = false;
        Get.snackbar('Error', 'Failed to read card ID. Please try again.');
        return;
      }

      // 4. Update nombor kad ke dalam database Supabase
      await _supabase
          .from('child')
          .update({
            'cardId': newCardId,
            'isActive': true, // Auto aktif bila kad di-link
          })
          .eq('childId', childData.value!.childId);

      // 5. Tutup sesi NFC dengan animasi berjaya (Khas untuk UI iOS)
      await FlutterNfcKit.finish(
        iosAlertMessage: "Sakoo card is successfully linked!",
      );
      isScanning.value = false;

      // 6. Kemas kini State UI & Refresh Dashboard
      var updatedChild = childData.value!;

      Get.find<ParentDashboardController>().fetchDashboardData();

      childData.value = updatedChild.copyWith(
        cardId: newCardId,
        isActive: true,
      );

      Get.snackbar(
        'Successful',
        'Sakoo card is successfully linked to ${updatedChild.childNickname}!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      await FlutterNfcKit.finish(iosErrorMessage: "Error while scanning.");
      isScanning.value = false;

      // Abaikan ralat jika pengguna tekan butang 'Cancel' masa scan
      if (e.toString().contains('408') || e.toString().contains('cancelled')) {
        Get.snackbar('Cancelled', 'Scanning session is cancelled.');
      } else {
        Get.snackbar('Error', 'This card is already linked to another child');
      }
    }
  }

  void showTransactionSheet(BuildContext context, {required bool isTopUp}) {
    final amountController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTopUp ? "Top Up Child Account" : "Withdraw Funds",
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'SF Pro Rounded',
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTopUp
                  ? "Enter the amount you want to transfer from your wallet to child card."
                  : "Enter the amount you want to pull back from child card to your wallet.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontFamily: 'SF Pro Rounded',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: "RM ",
                hintText: "0.00",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  double? amount = double.tryParse(
                    amountController.text.trim(),
                  );
                  if (amount == null || amount <= 0) {
                    Get.snackbar(
                      "Invalid Amount",
                      "Please key in a valid amount.",
                    );
                    return;
                  }
                  Get.back(); // close bottom sheet

                  final parentController =
                      Get.find<ParentDashboardController>();

                  final childId = childData.value!.childId;

                  if (isTopUp) {
                    parentController
                        .topUpChildBalance(childId, amount)
                        .then((_) => refreshChildAndTransactions());
                  } else {
                    parentController
                        .withdrawChildBalance(childId, amount)
                        .then((_) => refreshChildAndTransactions());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2B2B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // After a top-up/withdraw goes through, sync this page's local childData
  // (balance) with the freshly fetched list from ParentDashboardController,
  // then reload this child's transaction history + weekly summary.
  void refreshChildAndTransactions() {
    final parentController = Get.find<ParentDashboardController>();
    final currentChild = childData.value;
    if (currentChild != null) {
      final index = parentController.childrenList.indexWhere(
        (c) => c.childId == currentChild.childId,
      );
      if (index != -1) {
        childData.value = parentController.childrenList[index];
      }
    }
    fetchChildTransactions();
  }

  // modal to edit child information
  void showEditChildSheet(BuildContext context, ChildModel child) {
    deactivationSlidesRemaining.value = 3;
    isDeactivatedMode.value = false;

    // seed the draft auto top-up state from the current child record
    editAutoTopUpEnabled.value = child.autoTopUpEnabled;
    editAutoTopUpFrequency.value = child.autoTopUpFrequency;
    editAutoTopUpDay.value = child.autoTopUpDay;

    Get.bottomSheet(
      EditChildSheet(controller: this, child: child),
      isScrollControlled: true,
    );
  }

  // Persist nickname, daily limit, and auto top-up schedule in one go.
  // Called by EditChildSheet's Save Changes button.
  Future<void> saveChildEdits({
    required String newNickname,
    required double newDailyLimit,
    required bool autoTopUpEnabled,
    required double autoTopUpAmount,
    required String autoTopUpFrequency,
    required int autoTopUpDay,
  }) async {
    final current = childData.value;
    if (current == null) return;

    try {
      await _supabase
          .from('child')
          .update({
            'childNickname': newNickname,
            'dailyLimit': newDailyLimit,
            'autoTopUpEnabled': autoTopUpEnabled,
            'autoTopUpAmount': autoTopUpAmount,
            'autoTopUpFrequency': autoTopUpFrequency,
            'autoTopUpDay': autoTopUpDay,
          })
          .eq('childId', current.childId);

      childData.value = current.copyWith(
        childNickname: newNickname,
        dailyLimit: newDailyLimit,
        autoTopUpEnabled: autoTopUpEnabled,
        autoTopUpAmount: autoTopUpAmount,
        autoTopUpFrequency: autoTopUpFrequency,
        autoTopUpDay: autoTopUpDay,
      );

      Get.find<ParentDashboardController>().fetchDashboardData();

      Get.back();
      Get.snackbar(
        "Success",
        "Card information updated successfully",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.1),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update info: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
      );
    }
  }

  // The Card Status slider (activate/deactivate) stays driven from the
  // controller since it already depends on controller-level Rx state shared
  // with showEditChildSheet's draft fields.
  Widget buildCardStatusSlider(ChildModel child) {
    return Column(
      children: [
        // slider deactivation (3 times slide)
        // 🚀 SLIDER ACTIVATE / DEACTIVATE
        Obx(() {
          // Dapatkan status terkini dari childData.value
          bool isCardActive = childData.value?.isActive ?? false;
          int slides = deactivationSlidesRemaining.value;
          bool isSliderMode = isDeactivatedMode.value;

          return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: !isSliderMode
                    // 1. PAPARAN ASAL: BUTANG
                    ? SizedBox(
                        key: const ValueKey('action_button'),
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            isDeactivatedMode.value = true;
                            // set the number of slides needed by status. for now, 3 -> deactivate, once -> activate
                            deactivationSlidesRemaining.value = isCardActive
                                ? 3
                                : 1;
                          },
                          style: ElevatedButton.styleFrom(
                            // Merah untuk Deactivate, Hijau untuk Activate
                            backgroundColor: isCardActive
                                ? Colors.redAccent
                                : Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isCardActive ? "Deactivate Card" : "Activate Card",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SF Pro Rounded',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    // 2. PAPARAN SLIDER
                    : ActionSlider.standard(
                        key: ValueKey('action_slider_$isCardActive'),
                        width: double.infinity,
                        height: 52,
                        direction: TextDirection.ltr,
                        rolling: false,

                        toggleColor: isCardActive
                            ? (slides == 1 ? Colors.redAccent : Colors.white)
                            : Colors.green,
                        backgroundColor: isCardActive
                            ? (slides == 1
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.grey[200])
                            : Colors.green.withOpacity(0.1),
                        child: Text(
                          isCardActive
                              ? (slides > 1
                                    ? "Slide $slides times to deactivate"
                                    : "Slide one last time to confirm.")
                              : "Slide to activate card",
                          style: TextStyle(
                            color: isCardActive
                                ? (slides == 1 ? Colors.white : Colors.black87)
                                : Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF Pro Rounded',
                          ),
                        ),
                        action: (controller) async {
                          controller.loading();
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );

                          // Logik: Kalau Deactivate & belum cukup 3 kali slide
                          if (isCardActive && slides > 1) {
                            controller
                                .reset(); // Biar slider gerak balik kiri DULU
                            await Future.delayed(
                              const Duration(milliseconds: 400),
                            ); // Tunggu animasi selesai
                            deactivationSlidesRemaining.value -=
                                1; // BARU update UI state
                          }
                          // Logik: Cukup 3 kali Deactivate ATAU 1 kali Activate
                          else {
                            controller.success();

                            try {
                              bool newStatus =
                                  !isCardActive; // Terbalikkan status (true -> false, false -> true)

                              // Update di Supabase
                              await _supabase
                                  .from('child')
                                  .update({'isActive': newStatus})
                                  .eq('childId', child.childId);

                              // Update State Tempatan
                              var updatedChild = childData.value!;
                              childData.value = updatedChild.copyWith(
                                isActive: newStatus, // Status baru
                              );

                              Get.find<ParentDashboardController>()
                                  .fetchDashboardData();

                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              ); // Biar tengok success hijau/merah
                              Get.back();

                              // Tunjuk mesej berbeza ikut status
                              Get.snackbar(
                                newStatus
                                    ? "Card Activated"
                                    : "Card Deactivated",
                                newStatus
                                    ? "${updatedChild.childNickname}'s card is now active."
                                    : "${updatedChild.childNickname}'s card has been temporarily frozen.",
                                backgroundColor: newStatus
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                colorText: Colors.black87,
                                snackPosition: SnackPosition.TOP,
                              );
                            } catch (e) {
                              controller.reset();
                              // Reset bilangan slide kalau gagal
                              deactivationSlidesRemaining.value = isCardActive
                                  ? 3
                                  : 1;
                              Get.snackbar(
                                "Error",
                                "Failed to update card status: $e",
                                backgroundColor: Colors.redAccent.withOpacity(
                                  0.1,
                                ),
                              );
                            }
                          }
                        },
                      ),
              );
            }),

            // Butang Cancel Deactivation / Activation
            Obx(
              () => isDeactivatedMode.value
                  ? Column(
                      children: [
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            isDeactivatedMode.value = false;
                            // Reset ikut status semasa kalau di-cancel
                            deactivationSlidesRemaining.value =
                                (childData.value?.isActive ?? false) ? 3 : 1;
                          },
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontFamily: 'SF Pro Rounded',
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            if (isDeactivatedMode.value) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  isDeactivatedMode.value = false;
                  deactivationSlidesRemaining.value = 3; // reset slider
                },
                child: const Text(
                  "Cancel Deactivation",
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'SF Pro Rounded',
                  ),
                ),
              ),
            ],
      ],
    );
  }

  @override
  void onClose() {
    // Langkah keselamatan: Tutup sesi NFC jika user terus back keluar dari page
    FlutterNfcKit.finish();
    super.onClose();
  }
}