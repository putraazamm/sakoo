// lib/screens/auth/sign_up_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/signup_controller.dart';
import 'login_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Memulakan (Inject) Controller ke dalam skrin
    final SignUpController controller = Get.put(SignUpController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF252525), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Tajuk Utama Skrin
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF252525),
                    fontFamily: 'SF Pro Rounded',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign up to start managing your child's cashless wallet.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontFamily: 'SF Pro Rounded',
                  ),
                ),
                const SizedBox(height: 32),

                // Medan Input: Nama Penuh
                _buildTextField(
                  label: "Full Name",
                  hint: "Enter your full name",
                  icon: Icons.person_outline,
                  textController: controller.nameController,
                  validator: controller.validateName,
                ),
                const SizedBox(height: 20),

                // Medan Input: Emel
                _buildTextField(
                  label: "Email Address",
                  hint: "example@email.com",
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textController: controller.emailController,
                  validator: controller.validateEmail,
                ),
                const SizedBox(height: 20),

                // Medan Input: Kata Laluan
                Obx(() => _buildTextField(
                  label: "Password",
                  hint: "Minimum 6 characters",
                  icon: Icons.lock_outline,
                  isObscure: controller.obscurePassword.value,
                  textController: controller.passwordController,
                  validator: controller.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.black45,
                    ),
                    onPressed: () => controller.obscurePassword.toggle(),
                  ),
                )),
                const SizedBox(height: 20),

                // Medan Input: Sahkan Kata Laluan
                Obx(() => _buildTextField(
                  label: "Confirm Password",
                  hint: "Repeat your password",
                  icon: Icons.lock_clock_outlined,
                  isObscure: controller.obscureConfirmPassword.value,
                  textController: controller.confirmPasswordController,
                  validator: controller.validateConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureConfirmPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.black45,
                    ),
                    onPressed: () => controller.obscureConfirmPassword.toggle(),
                  ),
                )),
                
                const SizedBox(height: 40),

                // Butang Submit / Daftar Akaun
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : () => controller.signUpUser(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF252525),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black26,
                      elevation: 4,
                      shadowColor: const Color(0xFF252525),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Rounded',
                            ),
                          ),
                  ),
                )),
                
                const SizedBox(height: 24),

                // Pautan Footer ke Skrin Log Masuk
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.black54, fontFamily: 'SF Pro Rounded', fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Get.off(() => LoginScreen()),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Color(0xFF252525),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Rounded',
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Fungsi Pembantu (Helper) untuk Widget Input ---
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController textController,
    required String? Function(String?) validator,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            fontFamily: 'SF Pro Rounded',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: textController,
          obscureText: isObscure,
          keyboardType: keyboardType,
          validator: validator,
          cursorColor: const Color(0xFF252525),
          style: const TextStyle(fontFamily: 'SF Pro Rounded', fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black45, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            errorStyle: const TextStyle(fontFamily: 'SF Pro Rounded'),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF252525), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}