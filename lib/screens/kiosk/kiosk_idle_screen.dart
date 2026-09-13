// lib/screens/kiosk/kiosk_idle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/kiosk_controller.dart';

class KioskIdleScreen extends StatelessWidget {
  const KioskIdleScreen({Key? key}) : super(key: key);

  void _confirmLogout(BuildContext context, KioskController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          controller.t('Log Out', 'Log Keluar'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          controller.t(
            'Are you sure you want to log out of this kiosk?',
            'Adakah anda pasti mahu log keluar daripada kiosk ini?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              controller.t('Cancel', 'Batal'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              controller.t('Log Out', 'Log Keluar'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExitKioskMode(BuildContext context, KioskController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          controller.t('Exit Kiosk Mode', 'Keluar Mod Kiosk'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          controller.t(
            'Return to your merchant app. You will remain logged in.',
            'Kembali ke aplikasi merchant anda. Anda akan kekal log masuk.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              controller.t('Cancel', 'Batal'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.close(2); // closes the confirm dialog AND the kiosk screen
              controller.exitKioskMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF252525),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              controller.t('Exit', 'Keluar'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KioskController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Main content ────────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      SvgPicture.asset(
                        'lib/assets/images/sakoo-merchant-logo.svg',
                        height: 56,
                      ),
                      const SizedBox(height: 10),
                      Obx(() => Text(
                            controller.t('Ordering Kiosk', 'Kiosk Pesanan'),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          )),

                      const SizedBox(height: 52),

                      // Illustration
                      _KioskIllustration(),

                      const SizedBox(height: 52),

                      // Start Order button
                      Obx(() => controller.isProcessing.value
                          ? const CircularProgressIndicator(
                              color: Color(0xFF252525))
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      controller.scanCard(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF252525),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    controller.t(
                                        'Start Order', 'Mula Pesanan'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )),
                    ],
                  ),
                ),

                // ── Language toggle ─────────────────────────────────
                Obx(() => Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LangButton(
                            label: 'Bahasa Malaysia',
                            isSelected: controller.lang.value == 'ms',
                            onTap: () => controller.lang.value = 'ms',
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '|',
                              style: TextStyle(
                                  color: Colors.grey[300], fontSize: 16),
                            ),
                          ),
                          _LangButton(
                            label: 'English',
                            isSelected: controller.lang.value == 'en',
                            onTap: () => controller.lang.value = 'en',
                          ),
                        ],
                      ),
                    )),
              ],
            ),

            // ── Merchant name (top left) ──────────────────────────
            Positioned(
              top: 12,
              left: 16,
              child: Obx(() => Text(
                    controller.kioskMerchantName.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF252525),
                    ),
                  )),
            ),

            // ── Exit Kiosk Mode / Log Out button (top right) ──────
            Positioned(
              top: 8,
              right: 8,
              child: Obx(() {
                final cameFromMerchantApp =
                    controller.enteredFromMerchantApp.value;
                return IconButton(
                  icon: Icon(
                    cameFromMerchantApp
                        ? Icons.arrow_back_rounded
                        : Icons.logout_rounded,
                    color: Colors.grey,
                  ),
                  tooltip: cameFromMerchantApp
                      ? controller.t('Exit Kiosk Mode', 'Keluar Mod Kiosk')
                      : controller.t('Log Out', 'Log Keluar'),
                  onPressed: () => cameFromMerchantApp
                      ? _confirmExitKioskMode(context, controller)
                      : _confirmLogout(context, controller),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kiosk illustration (inline SVG-like drawn with Flutter widgets) ──
class _KioskIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
          ),
          // Inner circle
          Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xFFE8E8E8),
              shape: BoxShape.circle,
            ),
          ),
          // Kiosk icon
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.point_of_sale_rounded,
                size: 80,
                color: const Color(0xFF252525),
              ),
              const SizedBox(height: 4),
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF252525).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          // NFC badge
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.contactless, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('NFC',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language button ──────────────────────────────────────────────────
class _LangButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.grey[400],
        ),
      ),
    );
  }
}