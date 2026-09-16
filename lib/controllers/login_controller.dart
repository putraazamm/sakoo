// -> lib/controllers/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';
import '../screens/parent/parent_main_shell.dart';
import '../screens/merchant/merchant_main_shell.dart';
import '../screens/kiosk/kiosk_idle_screen.dart';
import '../controllers/kiosk_controller.dart';

class LoginController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      Get.snackbar(
        "Please fill all the fields.",
        "Email/Username and Password cannot left blank.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    try {
      isLoading.value = true;

      final List<dynamic> rows = await _supabase.rpc('verify_login', params: {
        'p_email': email.trim(),
        'p_password': password.trim(),
      });

      if (rows.isEmpty) {
        throw Exception('Invalid email or password.');
      }

      final userData = Map<String, dynamic>.from(rows.first);

      // save session to disk
      await SessionService.saveSession(Map<String, dynamic>.from(userData));

      String role = userData['role'];
      String name = userData['name'];

      Get.snackbar(
        "Successful",
        "Welcome back, $name!",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green[900]!.withOpacity(0.1),
        colorText: Colors.green[900],
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );

      if (role == 'parent') {
        Get.offAll(() => const ParentMainShell(), arguments: userData);
      } else if (role == 'merchant') {
        Get.offAll(() => const MerchantMainShell(), arguments: userData);
      } else if (role == 'kiosk') {
        final kiosk = Get.put(KioskController(), permanent: true);
        kiosk.initialize(
          merchantId: userData['id']?.toString() ?? '',
          merchantName: userData['name']?.toString() ?? '',
          cameFromMerchantApp: false,
        );
        Get.offAll(() => const KioskIdleScreen());
      } else if (role == 'admin') {
        Get.snackbar("Akses Admin", "Halaman admin belum disediakan.");
      } else {
        Get.snackbar("Ralat", "Peranan pengguna tidak dikenali.");
      }
    } catch (error) {
      Get.snackbar(
        "Log In Failed",
        "Email or Password is wrong.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isLoading.value = false;
    }
  }
}