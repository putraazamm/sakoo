// lib/controller/sign_up_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpController extends GetxController {
  final _supabase = Supabase.instance.client;
  final formKey = GlobalKey<FormState>();

  // Text Editing Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Observers untuk state UI
  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var obscureConfirmPassword = true.obs;

  // --- Fungsi Validasi ---
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please input your full name';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please input your email address';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Email format is not valid';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please input your password';
    }
    if (value.length < 6) {
      return 'Password must be greater than 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Password not matches';
    }
    return null;
  }

  // --- Fungsi Daftar Akaun ke Supabase ---
  Future<void> signUpUser() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      await _supabase.from('user').insert({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'role': 'parent',
      });

        Get.snackbar(
          "Pendaftaran Berjaya",
          "Akaun anda telah berjaya dicipta! Sila log masuk.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Bersihkan borang & bawa pengguna ke skrin Login
        clearControllers();
        Get.offNamed('lib/screens/auth/login_screen.dart');
      
    } catch (e) {
      Get.snackbar(
        "Sign Up Error",
        e.toString().replaceAll("Exception:", "").trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearControllers() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
