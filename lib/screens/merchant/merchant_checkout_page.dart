import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
// import 'package:get/get_connect/http/src/http/io/http_request_io.dart';
import 'package:lottie/lottie.dart';
import 'package:sakoo/controllers/merchant_dashboard_controller.dart';
import 'package:sakoo/controllers/merchant_new_order_controller.dart';
// import 'package:sakoo/models/models.dart';
// import 'package:sakoo/screens/merchant/merchant_main_shell.dart';
import 'package:sakoo/screens/merchant/merchant_new_order_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambah import Supabase
// import 'merchant_dashboard_page.dart';

class MerchantCheckoutScreen extends StatelessWidget {
  const MerchantCheckoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ambil data yang di-pass dari skrin sebelumnya
    final Map<String, dynamic> args = Get.arguments;
    final List<Map<String, dynamic>> items = args['items'];
    final double totalAmount = args['total'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Order Summary',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Items to purchase:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Senarai barang yang dibeli
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item['quantity']}x ${item['name']}'),
                          Text(
                            'RM ${item['subtotal'].toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Garis Pemisah
              const Divider(thickness: 1.5),
              const SizedBox(height: 16),

              // Jumlah Keseluruhan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'RM ${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Butang Pay (Aktifkan NFC)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _startNFCSession(context, totalAmount, items),
                  icon: const Icon(
                    Icons.contactless,
                    color: Colors.white,
                    size: 28,
                  ),
                  label: const Text(
                    'Tap NFC Card to Pay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252525),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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

  // Logik Sebenar Imbasan NFC Kit
  Future<void> _startNFCSession(
    BuildContext context,
    double totalAmount,
    List<Map<String, dynamic>> items,
  ) async {
    // Semak ketersediaan hardware NFC pada peranti merchant
    var nfcAvailability = await FlutterNfcKit.nfcAvailability;
    if (nfcAvailability != NFCAvailability.available) {
      Get.snackbar(
        "NFC is not available",
        "Please turn on the NFC in settings.",
        backgroundColor: Colors.black38.withOpacity(0.5),
        colorText: Colors.white,
      );
      return;
    }

    // Papar dialog mengundi / menunggu imbasan (const dibuang dari AlertDialog)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('lib/assets/images/nfc-scan.json'),
            const SizedBox(height: 16),
            const Text(
              'Ready to scan...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please tap the student card on the back of the phone.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      // Mulakan imbasan kad NFC dengan had masa (timeout) 15 saat
      var tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 15),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Scan your student card",
      );

      String cardUid = tag.id; // Dapatkan Unique ID kad

      // Matikan sesi hardware NFC sebaik sahaja dapat ID
      await FlutterNfcKit.finish();

      // Hantar UID ke Supabase RPC untuk pemprosesan baki kewangan
      if (context.mounted) {
        await _executePaymentOnDatabase(context, cardUid, totalAmount, items);
      }
    } catch (e) {
      // Jika error, panggil finish untuk tamatkan polling
      await FlutterNfcKit.finish();

      // Tutup dialog Lottie
      if (context.mounted) Navigator.of(context).pop();

      Get.snackbar(
        "Scan Cancelled",
        "Failed to read card or session timeout.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _executePaymentOnDatabase(
    BuildContext context,
    String nfcUid,
    double amount,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final String? currentMerchantId =
          Get.find<MerchantDashboardController>().merchantData['id'] as String?;

      if (currentMerchantId == null || currentMerchantId.isEmpty) {
        if (context.mounted) Navigator.of(context).pop(); // Tutup dialog scan
        Get.snackbar("Error", "Invalid merchant session. Please re-login.");
        return;
      }

      // explicitly convert items to a plain List for JSONB
      final List<Map<String, dynamic>> cleanItems = items
          .map(
            (item) => {
              'name': item['name']?.toString() ?? '',
              'quantity': (item['quantity'] as num).toInt(),
              'subtotal': (item['subtotal'] as num).toDouble(),
              'category': item['category']?.toString() ?? 'Others',
            },
          )
          .toList();

      String mainCategory = 'Others';
      if (items.isNotEmpty && items[0]['category'] != null) {
        mainCategory = items[0]['category'];
      }

      debugPrint("=== NFC Payment Attempt");
      debugPrint("NFC UID : $nfcUid");
      debugPrint("Merchant Id : $currentMerchantId");
      debugPrint("Amount : $amount");
      debugPrint("Items : $cleanItems");

      // Panggil fungsi database 'process_nfc_payment' yang dicipta dalam SQL editor
      final response = await supabase.rpc(
        'process_nfc_payment',
        params: {
          'p_nfc_uid': nfcUid,
          'p_merchant_id': currentMerchantId,
          'p_amount': amount,
          'p_category': mainCategory,
          'p_order_details': cleanItems,
        },
      );

      debugPrint('Raw response: $response');
      debugPrint('Response runtimeType: ${response.runtimeType}');

      // close lottie scanning dialog after database response is done
      if (context.mounted) Navigator.of(context).pop();

      Map<String, dynamic> result;
      if (response == null) {
        Get.snackbar(
          'Error',
          'Server returned null. Check Supabase function logs.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
        return;
      } else if (response is Map<String, dynamic>) {
        result = response;
      } else if (response is Map) {
        result = Map<String, dynamic>.from(response);
      } else if (response is String) {
        // sometimes jsonb comes back as a raw JSON string
        result = Map<String, dynamic>.from(
          (response).isNotEmpty
              ? Map<String, dynamic>.from(Uri.splitQueryString(response))
              : {},
        );
      } else {
        Get.snackbar(
          'Error',
          'Unexpected response type: ${response.runtimeType}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
        return;
      }

      debugPrint('Parsed result: $result');

      final dynamic rawSuccess = result['success'];
      final bool isSuccess =
          rawSuccess == true || rawSuccess?.toString().toLowerCase() == 'true';
      final String message = result['message']?.toString() ?? 'Unknown error.';

      debugPrint('isSuccess: $isSuccess');
      debugPrint('message: $message');

      if (isSuccess) {
        if (Get.isRegistered<MerchantNewOrderController>()) {
          final newOrderCtrl = Get.find<MerchantNewOrderController>();
          newOrderCtrl.clearCart();
          newOrderCtrl.fetchMenuItems();
        }

        await Get.find<MerchantDashboardController>().fetchDashboardData();

        Get.snackbar(
          "Payment Successful!",
          "RM ${amount.toStringAsFixed(2)} has been added to your account.']}.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        // Seterusnya kau boleh clearkan cart atau hantar merchant balik ke Dashboard:
        Get.offAll(() => const MerchantNewOrderScreen());

      } else {
        Get.snackbar(
          "Transaction Failed",
          message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (error, stackTrace) {
      if (context.mounted) Navigator.of(context).pop(); // Tutup dialog scan

      debugPrint("=== Supabase RPC Error ===");
      debugPrint("Error : $error");
      debugPrint("StackTrace : $stackTrace");

      Get.snackbar(
        "System Error",
        error.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    }
  }
}
