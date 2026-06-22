import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';
import '../screens/welcome_screen.dart';

class MerchantDashboardController extends GetxController {
  final _supabase = Supabase.instance.client;

  var isLoading = true.obs;
  var merchantData = <String, dynamic>{}.obs;
  var merchantName = "Loading...".obs;
  var merchantBalance = 0.0.obs;
  var transactions = [].obs;
  var selectedDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    _initSession();
  }

  Future<void> _initSession() async {
    if (Get.arguments != null && Get.arguments is Map) {
      merchantData.value = Map<String, dynamic>.from(Get.arguments);
    } else {
      final saved = await SessionService.loadSession();
      if (saved != null) {
        merchantData.value = Map<String, dynamic>.from(saved);
      }
    }

    if (merchantData['id'] == null) {
      // no session at all -> return to welcome screen.
      await SessionService.clearSession();
      Get.offAll(() => const WelcomeScreen());
      return;
    }

    merchantName.value = merchantData['name'] ?? 'Merchant';
    merchantBalance.value = (merchantData['balance'] ?? 0.0).toDouble();

    await fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;

      final merchantId = merchantData['id'];
      if (merchantId == null) {
        throw Exception("Session invalid. Please log in again.");
      }

      // fetch merchant from user table
      final userDbData = await _supabase
          .from('user')
          .select('name, balance')
          .eq('id', merchantId)
          .single();

      merchantName.value = userDbData['name'] ?? 'Merchant';
      merchantBalance.value = (userDbData['balance'] ?? 0.0).toDouble();
      merchantData['name'] = merchantName.value;
      merchantData['balance'] = merchantBalance.value;

      // fetch the transaction of this particular merchant
      await fetchTransactions(merchantId);

      await SessionService.saveSession(Map<String, dynamic>.from(merchantData));
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      Get.snackbar(
        "Ralat Pangkalan Data",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTransactions(String merchantId) async {
    try {
      // Ditambah .order() supaya transaksi terbaharu sentiasa duduk di atas
      var query = _supabase
          .from('transaction')
          .select('*, child(childName)') // Hubungan join ke table child
          .eq('merchantId', merchantId);

      // Jika user memilih tanggal, saring datanya dengan tepat mengikut zon masa UTC
      if (selectedDate.value != null) {
        final startOfDayLocal = DateTime(
          selectedDate.value!.year,
          selectedDate.value!.month,
          selectedDate.value!.day,
        );
        final endOfDayLocal = startOfDayLocal.add(const Duration(days: 1));

        // toUtc to make sure the time is Malaysia time before sending to Supabase
        query = query
            .gte('createdAt', startOfDayLocal.toUtc().toIso8601String())
            .lt('createdAt', endOfDayLocal.toUtc().toIso8601String());
      }

      final res = await query.order('createdAt', ascending: false);
      transactions.assignAll(res);
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
  }

  // --- Fungsi Memilih Tanggal Filter ---
  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(2024), // Disesuaikan ke tahun sistem mula berjalan
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF252525),
            colorScheme: const ColorScheme.light(primary: Color(0xFF252525)),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDate.value = picked;
      // Muat ulang transaksi dengan filter tanggal yang baru
      if (merchantData['id'] != null) {
        fetchTransactions(merchantData['id']);
      }
    }
  }

  // --- Fungsi Reset Filter Tanggal ---
  void clearDateFilter() {
    selectedDate.value = null;
    if (merchantData['id'] != null) {
      fetchTransactions(merchantData['id']);
    }
  }

  // --- Fungsi Keluar (Logout) ---
  void logout() async {
    await SessionService.clearSession();
    merchantData.clear();
    transactions.clear();
    merchantName.value = '';
    merchantBalance.value = 0.0;
    await Future.delayed(const Duration(milliseconds: 100));
    Get.offAll(() => const WelcomeScreen());
  }

  // --- withdraw funds --- TODO: connect with bank API to directly transfer to bank account safely
  Future<void> withdrawFunds(double amount) async {
    if (amount <= 0) {
      Get.closeAllSnackbars();
      Get.snackbar(
        "Invalid Amount",
        "Please enter a valid amount to withdraw.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (amount > merchantBalance.value) {
      Get.closeAllSnackbars();
      Get.snackbar(
        "Insufficient Balance",
        "Your account balance is not enough for this withdrawal.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final merchantId = merchantData['id'];

      double newBalance = merchantBalance.value - amount;

      // update to 'user' table
      await _supabase
          .from('user')
          .update({'balance': newBalance})
          .eq('id', merchantId);

      // update to 'transaction' table
      await _supabase.from('transaction').insert({
        'merchantId': merchantId,
        'merchantName': 'Bank Withdrawal',
        'category': 'Withdrawal',
        // 'type': 'withdraw',
        'amount': amount,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      // update local state (UI)
      merchantBalance.value = newBalance;
      merchantData['balance'] = newBalance;
      await SessionService.saveSession(Map<String, dynamic>.from(merchantData));

      // refresh list of transaction
      await fetchTransactions(merchantId);

      Get.back();
      Get.closeAllSnackbars();
      Get.snackbar(
        "Withdrawal Successful",
        "RM ${amount.toStringAsFixed(2)} has been withdrawn to your bank account.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint("Withdraw error: $e");
      Get.closeAllSnackbars();
      Get.snackbar(
        "Error",
        "Failed to process withdrawal: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
