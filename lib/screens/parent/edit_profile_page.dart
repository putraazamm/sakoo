// lib/screens/parent/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/parent_dashboard_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ParentDashboardController controller =
      Get.find<ParentDashboardController>();
  final _supabase = Supabase.instance.client;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: controller.parentData['name']);
    emailController = TextEditingController(
      text: controller.parentData['email'],
    );
    passwordController = TextEditingController(); 
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final parentId = controller.parentData['id'];

    if (parentId == null) {
      Get.snackbar("Ralat", "Sesi tidak sah. Sila log masuk semula.");
      return;
    }

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      Get.snackbar("Ralat", "Nama dan Emel tidak boleh dibiarkan kosong.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> updateData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
      };

      if (passwordController.text.trim().isNotEmpty) {
        updateData['password'] = passwordController.text.trim();
      }

      await _supabase.from('user').update(updateData).eq('id', parentId);

      controller.parentData['name'] = updateData['name'];
      controller.parentData['email'] = updateData['email'];
      controller.parentName.value = updateData['name'];

      Get.closeAllSnackbars();

      Get.snackbar(
        "Success",
        "Profile has been updated successfully!",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green[800],
        snackPosition: SnackPosition.TOP,
      );

      // (Pilihan) Kosongkan medan password selepas berjaya tukar
      passwordController.clear();
    } catch (e) {
      Get.closeAllSnackbars();
      Get.snackbar(
        "Error",
        "Failed to update profile: $e",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Rounded',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture Edit
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.snackbar(
                        "Profile Picture",
                        "Feature to upload picture coming soon.",
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF252525),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Form Fields
              _buildTextField(
                "Full Name",
                "Enter your name",
                nameController,
                Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                "Email Address",
                "Enter your email",
                emailController,
                Icons.email_outlined,
                isEmail: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                "New Password",
                "Leave blank to keep current",
                passwordController,
                Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252525),
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Rounded',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController textController,
    IconData icon, {
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'SF Pro Rounded',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: textController,
          obscureText: isPassword,
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF252525)),
            ),
          ),
        ),
      ],
    );
  }
}
