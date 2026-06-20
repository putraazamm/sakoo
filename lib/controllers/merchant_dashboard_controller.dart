import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    if (Get.arguments != null) {
      if (Get.arguments is Map) {
        merchantData.value = Map<String, dynamic>.from(Get.arguments);

        if (merchantData['name'] != null) {
          merchantName.value = merchantData['name'];
        }

        if (merchantData['balance'] != null) {
          merchantBalance.value = (merchantData['balance']).toDouble();
        }
      }

      print("=== Data Merchant Dikutip Dari Arguments ===");
      print("ID Merchant: ${merchantData['id']}");
      print("Nama: ${merchantName.value}");
    }

    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;

      final merchantId = merchantData['id'];
      if (merchantId == null) {
        throw Exception("Session invalid. Please log in again.");
      }

      // 2. Ambil 'name' dan 'balance' terkini dari tabel 'user'
      final userDbData = await _supabase
          .from('user')
          .select('name, balance')
          .eq('id', merchantId)
          .single();

      merchantName.value = userDbData['name'] ?? 'Merchant';
      merchantBalance.value = (userDbData['balance'] ?? 0.0).toDouble();

      // Perbarui map data lokal
      merchantData['name'] = merchantName.value;
      merchantData['balance'] = merchantBalance.value;

      // 3. Ambil riwayat transaksi merchant ini
      await fetchTransactions(merchantId);
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
  void logout() {
    merchantData.clear();
    Get.offAllNamed('/login');
  }
}
