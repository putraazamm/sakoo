import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/parent_dashboard_controller.dart';

class AddChildPage extends StatelessWidget {
  const AddChildPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ParentDashboardController controller =
        Get.find<ParentDashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Child',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Register Your Child',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Please fill in the details below to create a new child account.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // 1. Input Nama Penuh (childName)
              _buildTextField(
                label: 'Full Name',
                hint: "Child's full name as per ID",
                controller: controller.nameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // 2. Input Nama Panggilan (childNickname)
              _buildTextField(
                label: 'Nickname',
                hint: 'E.g. Amru, Aliyah',
                controller: controller.nicknameController,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),

              // 3. Input Tarikh Lahir (dob) - Using Date Picker
              _buildDatePickerField(
                label: 'Date of Birth',
                hint: 'Select your date of birth',
                controller: controller.dobController,
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 16),

              // 4. Input Kad Pengenalan / NRIC (bigint di database)
              _buildTextField(
                label: 'Identification No. / NRIC',
                hint: 'E.g. 120525041234 (Numbers only)',
                controller: controller.nricController,
                icon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // 5. Input Alamat Baris 1 (address_line1)
              _buildTextField(
                label: 'Address Line 1',
                hint: 'No. Rumah, Jalan, Taman',
                controller: controller.address1Controller,
                icon: Icons.home_outlined,
              ),
              const SizedBox(height: 16),

              // 6. Input Alamat Baris 2 (address_line2 - Optional)
              _buildTextField(
                label: 'Address Line 2 (Optional)',
                hint: 'Daerah, Poskod, Negeri',
                controller: controller.address2Controller,
                icon: Icons.map_outlined,
              ),
              const SizedBox(height: 16),

              // 7. Input Nama Sekolah (childSchool)
              _buildTextField(
                label: 'School Name',
                hint: 'E.g. SK Durian Tunggal',
                controller: controller.schoolController,
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 32),

              // --- BUTTON CONFIRM DENGAN LOADING STATE (OBX) ---
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.addNewChild(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF1B4332,
                      ), // Warna tema hijau tua Sakoo
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
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
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1B4332),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget untuk Date Picker dengan Calendar
  Widget _buildDatePickerField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
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
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true, // Make it read-only since we're using date picker
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1B4332),
                width: 1.5,
              ),
            ),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: Get.context!,
              initialDate: DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1B4332), // Sakoo green color
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (pickedDate != null) {
              // Format: YYYY-MM-DD
              String formattedDate =
                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
              controller.text = formattedDate;
            }
          },
        ),
      ],
    );
  }
}
