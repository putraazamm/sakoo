// -> lib/controllers/kiosk_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/kiosk/kiosk_menu_screen.dart';
import '../screens/welcome_screen.dart';
import '../services/session_service.dart';

class KioskController extends GetxController {
  final _supabase = Supabase.instance.client;

  // ── Kiosk merchant ID ────────────────────────────────────────
  // This is set from login — the kiosk user's own ID in the user table.
  // Items are fetched from the item table using this ID as merchantid.
  String kioskMerchantId = '';
  var kioskMerchantName = ''.obs;

  // ── Child session (after NFC scan) ───────────────────────────
  var childCardId    = ''.obs;
  var childName      = ''.obs;
  var childBalance   = 0.0.obs;
  var isCardScanned  = false.obs;

  // ── Menu ─────────────────────────────────────────────────────
  var menuItems     = <Map<String, dynamic>>[].obs;
  var isLoadingMenu = true.obs;
  var selectedCat   = 'All'.obs;

  // ── Cart: item UUID → quantity ────────────────────────────────
  var cart = <String, int>{}.obs;

  // ── UI flags ──────────────────────────────────────────────────
  var isProcessing = false.obs;
  var lang         = 'en'.obs; // 'en' | 'ms'

  // True when a merchant opened Kiosk mode from inside their own app
  // (Settings > Enter Kiosk Mode).
  var enteredFromMerchantApp = false.obs;

  // ── Realtime ─────────────────────────────────────────────────
  RealtimeChannel? _itemChannel;

  @override
  void onInit() {
    super.onInit();
  }

  void initialize({
    required String merchantId,
    required String merchantName,
    bool cameFromMerchantApp = false,
  }) {
    kioskMerchantId = merchantId;
    kioskMerchantName.value = merchantName;
    enteredFromMerchantApp.value = cameFromMerchantApp;
    fetchMenuItems();
    _subscribeToMenuChanges();
  }

  @override
  void onClose() {
    if (_itemChannel != null) {
      _supabase.removeChannel(_itemChannel!);
    }
    super.onClose();
  }

  // ── Menu ──────────────────────────────────────────────────────
  Future<void> fetchMenuItems() async {
    try {
      isLoadingMenu.value = true;
      final data = await _supabase
          .from('item')
          .select()
          .eq('merchantid', kioskMerchantId) // was missing — was pulling ALL merchants' items
          .eq('isavailable', true)
          .order('category')
          .order('name');
      menuItems.assignAll(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('KioskController.fetchMenuItems: $e');
    } finally {
      isLoadingMenu.value = false;
    }
  }
  
  void _subscribeToMenuChanges() {
    if (kioskMerchantId.isEmpty) return;
    _itemChannel = _supabase
        .channel('kiosk-item-changes-$kioskMerchantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'item',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'merchantid',
            value: kioskMerchantId,
          ),
          callback: (payload) => fetchMenuItems(),
        )
        .subscribe();
  }

  List<String> get categories {
    final cats = menuItems
        .map((e) => e['category'] as String? ?? 'Others')
        .toSet()
        .toList()
      ..sort();
    return ['All', ...cats];
  }

  List<Map<String, dynamic>> get filteredItems {
    if (selectedCat.value == 'All') return menuItems;
    return menuItems
        .where((e) => e['category'] == selectedCat.value)
        .toList();
  }

  // ── Cart ──────────────────────────────────────────────────────
  double get totalPrice {
    double total = 0.0;
    for (final item in menuItems) {
      final id  = item['id'] as String;
      final p   = (item['price'] as num).toDouble();
      final qty = cart[id] ?? 0;
      total += p * qty;
    }
    return total;
  }

  double get remainingBalance => childBalance.value - totalPrice;

  bool get cartIsEmpty => totalPrice == 0;

  void increment(String id) {
    final item = menuItems.firstWhereOrNull((e) => e['id'] == id);
    if (item == null) return;
    final stock   = item['stock'] as int;
    final current = cart[id] ?? 0;
    if (current >= stock) {
      Get.snackbar(
        t('Out of Stock', 'Stok Habis'),
        t('No more stock available for this item.',
            'Tiada stok lagi untuk item ini.'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    cart[id] = current + 1;
  }

  void decrement(String id) {
    final current = cart[id] ?? 0;
    if (current > 0) cart[id] = current - 1;
  }

  // ── NFC scan to identify child ────────────────────────────────
  Future<void> scanCard(BuildContext context) async {
    final avail = await FlutterNfcKit.nfcAvailability;
    if (avail != NFCAvailability.available) {
      Get.snackbar(
        'NFC',
        t('Please enable NFC on this device.',
            'Sila aktifkan NFC pada peranti ini.'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('lib/assets/images/nfc-scan.json', height: 140),
            const SizedBox(height: 12),
            Text(
              t('Tap your student card', 'Ketuk kad pelajar anda'),
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              t('Place the card at the back of this device',
                  'Letakkan kad di belakang peranti ini'),
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 15),
        iosAlertMessage: 'Scan your student card',
      );
      await FlutterNfcKit.finish();
      if (context.mounted) Navigator.of(context).pop();
      await _loadChild(tag.id, context);
    } catch (e) {
      await FlutterNfcKit.finish();
      if (context.mounted) Navigator.of(context).pop();
      Get.snackbar(
        t('Scan Failed', 'Imbasan Gagal'),
        t('Could not read the card. Please try again.',
            'Gagal membaca kad. Sila cuba lagi.'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _loadChild(String cardId, BuildContext context) async {
    try {
      isProcessing.value = true;

      final row = await _supabase
          .from('child')
          .select('childId, childName, childBalance, isActive')
          .eq('cardId', cardId)
          .single();

      if (row['isActive'] == false) {
        Get.snackbar(
          t('Card Frozen', 'Kad Dibekukan'),
          t(
            'This card has been frozen. Please ask your parent to reactivate it.',
            'Kad ini telah dibekukan. Sila minta ibu bapa anda mengaktifkannya semula.',
          ),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      childCardId.value   = cardId;
      childName.value     = row['childName'] ?? '';
      childBalance.value  = (row['childBalance'] ?? 0.0).toDouble();
      isCardScanned.value = true;

      // Navigate to the menu screen
      Get.to(() => const KioskMenuScreen());
    } catch (_) {
      Get.snackbar(
        t('Card Not Found', 'Kad Tidak Dijumpai'),
        t(
          'This card is not registered in the system.',
          'Kad ini tidak didaftarkan dalam sistem.',
        ),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // ── Payment ───────────────────────────────────────────────────
  Future<void> pay(BuildContext context) async {
    if (cartIsEmpty) {
      Get.snackbar(
        t('Empty Order', 'Pesanan Kosong'),
        t('Please add at least one item.', 'Sila tambah sekurang-kurangnya satu item.'),
      );
      return;
    }
    if (childBalance.value < totalPrice) {
      Get.snackbar(
        t('Insufficient Balance', 'Baki Tidak Mencukupi'),
        t('Your balance is too low to complete this purchase.',
            'Baki anda tidak mencukupi untuk membuat pembelian ini.'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isProcessing.value = true;

      final ordered = <Map<String, dynamic>>[];
      String? firstCategory;
      for (final item in menuItems) {
        final id  = item['id'] as String;
        final qty = cart[id] ?? 0;
        if (qty > 0) {
          ordered.add({
            'name'    : item['name'],
            'quantity': qty,
            'subtotal': (item['price'] as num).toDouble() * qty,
          });
          firstCategory ??= item['category']?.toString();
        }
      }

      final category = firstCategory ?? 'Food & Drink';

      final dynamic resp = await _supabase.rpc(
        'process_nfc_payment',
        params: {
          'p_nfc_uid'      : childCardId.value,
          'p_merchant_id'  : kioskMerchantId,
          'p_amount'       : totalPrice,
          'p_category'     : category,
          'p_order_details': ordered,
        },
      );

      if (resp == null) {
        Get.snackbar('Error',
            'No response from server. Check if kiosk merchant ID is configured.');
        return;
      }

      final result    = Map<String, dynamic>.from(resp);
      final isSuccess = result['success'] == true;
      final message   = result['message']?.toString() ?? '';

      if (isSuccess) {
        _showSuccess(context);
      } else {
        Get.snackbar(
          t('Payment Failed', 'Pembayaran Gagal'),
          message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint('KioskController.pay: $e');
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  void _showSuccess(BuildContext context) {
    final paid = totalPrice;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              t('Payment Successful!', 'Pembayaran Berjaya!'),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'RM ${paid.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('Thank you, ${childName.value}!',
                  'Terima kasih, ${childName.value}!'),
              style:
                  const TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Auto-return to idle after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _reset();
      Get.close(2);
    });
  }

  void _reset() {
    childCardId.value   = '';
    childName.value     = '';
    childBalance.value  = 0.0;
    isCardScanned.value = false;
    cart.clear();
    selectedCat.value   = 'All';
  }

  // ── i18n helper ───────────────────────────────────────────────
  String t(String en, String ms) => lang.value == 'en' ? en : ms;

  // ── Logout (dedicated kiosk device — clears the account entirely) ──
  Future<void> logout() async {
    await SessionService.clearSession();
    Get.offAll(() => const WelcomeScreen());
    Get.delete<KioskController>(force: true);
  }

  void exitKioskMode() {
    Get.delete<KioskController>(force: true);
  }
}