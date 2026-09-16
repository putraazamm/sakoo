// lib/screens/parent/add_funds_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/parent_dashboard_controller.dart';
// import '../parent/parent_dashboard_page.dart';

class AddFundsPage extends StatefulWidget {
  const AddFundsPage({Key? key}) : super(key: key);

  @override
  State<AddFundsPage> createState() => _AddFundsPageState();
}

class _AddFundsPageState extends State<AddFundsPage> {
  final ParentDashboardController controller =
      Get.find<ParentDashboardController>();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _formatInput(String value) {
    String cleanText = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanText.isEmpty) {
      _amountController.text = '';
      return;
    }

    double parsedValue = double.parse(cleanText) / 100;

    String formattedText = parsedValue.toStringAsFixed(2);

    _amountController.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  void _submitFunds() async {
    final String text = _amountController.text.trim();
    if (text.isEmpty || text == "0.00") {
      Get.snackbar("Info", "Please enter the right amount.");
      return;
    }

    final double? amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      Get.snackbar("Error", "Please enter the amount >= 0.");
      return;
    }

    // Panggil fungsi controller
    bool success = await controller.addFundsToWallet(amount);
    if (success) {
      Get.back();

      Future.delayed(const Duration(milliseconds: 150), () {
        Get.snackbar(
          "Successful!",
          "RM ${amount.toStringAsFixed(2)} successfully credited to your wallet.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(15),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Back Arrow + Title + Subtitle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Funds',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'The funds will be credited to your account.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),

                  // Input Section
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: TextField(
                        controller: _amountController,
                        textAlign: TextAlign.center,
                        // 👇 Tukar ke input nombor biasa sebab kita dah tak perlukan user tekan '.' (dot)
                        keyboardType: TextInputType.number,
                        // 👇 Panggil fungsi auto-format kita bila user taip
                        onChanged: _formatInput,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(top: 6.0),
                            child: Text(
                              'RM ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Action Buttons: Confirm & Cancel
                  Obx(
                    () => Row(
                      children: [
                        // Confirm Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : _submitFunds,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF252525),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Cancel Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => Get.back(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5E5E5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
