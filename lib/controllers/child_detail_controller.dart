// lib/controllers/child_detail_controller.dart

// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/child_model.dart';
import 'parent_dashboard_controller.dart';

class ChildDetailController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  var childData = Rx<ChildModel?>(null);
  var isScanning = false.obs;

  @override
  void onInit() {
    super.onInit();
    childData.value = Get.arguments as ChildModel;
  }

  Future<void> linkNfcCard() async {
    try {
      // 1. Semak ketersediaan NFC pada peranti
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        Get.snackbar(
          'NFC Error', 
          'Your device is not support NFC or NFC is not turned on.', 
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white,
        );
        return;
      }

      isScanning.value = true;
      
      // 2. Mula sesi imbasan (Sangat ringkas berbanding nfc_manager)
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 15),
        iosAlertMessage: "Please tap your Sakoo NFC card at the back of your device.",
      );

      // 3. Ekstrak UID (Unique ID) dari kad NFC
      // flutter_nfc_kit akan terus berikan ID dalam format Hex String
      String newCardId = tag.id;

      if (newCardId.isEmpty) {
        await FlutterNfcKit.finish(iosErrorMessage: "Failed to read card ID.");
        isScanning.value = false;
        Get.snackbar('Ralat', 'Gagal membaca nombor siri kad. Sila cuba lagi.');
        return;
      }

      // 4. Update nombor kad ke dalam database Supabase
      await _supabase.from('child').update({
        'cardId': newCardId,
        'isActive': true, // Auto aktif bila kad di-link
      }).eq('childId', childData.value!.childId);

      // 5. Tutup sesi NFC dengan animasi berjaya (Khas untuk UI iOS)
      await FlutterNfcKit.finish(iosAlertMessage: "Kad Sakoo berjaya dipautkan!");
      isScanning.value = false;

      // 6. Kemas kini State UI & Refresh Dashboard
      var updatedChild = childData.value!;
      
      Get.find<ParentDashboardController>().fetchDashboardData();
      
      childData.value = ChildModel(
        childId: updatedChild.childId,
        childName: updatedChild.childName,
        childNickname: updatedChild.childNickname,
        cardId: newCardId, // 👈 Update ID baru
        childBalance: updatedChild.childBalance,
        parentId: updatedChild.parentId,
        isActive: true, // 👈 Terus tukar status aktif
        dailyLimit: updatedChild.dailyLimit,
      );

      Get.snackbar(
        'Berjaya', 
        'Kad Sakoo berjaya dipautkan ke akaun ${updatedChild.childNickname}!', 
        backgroundColor: Colors.green, 
        colorText: Colors.white,
      );

    } catch (e) {
      await FlutterNfcKit.finish(iosErrorMessage: "Ralat semasa mengimbas.");
      isScanning.value = false;
      
      // Abaikan ralat jika pengguna tekan butang 'Cancel' masa scan
      if (e.toString().contains('408') || e.toString().contains('cancelled')) {
        Get.snackbar('Dibatalkan', 'Sesi imbasan NFC ditamatkan.');
      } else {
        Get.snackbar('Error', 'This card is already linked to another child');
      }
    }
  }

  @override
  void onClose() {
    // Langkah keselamatan: Tutup sesi NFC jika user terus back keluar dari page
    FlutterNfcKit.finish();
    super.onClose();
  }
}