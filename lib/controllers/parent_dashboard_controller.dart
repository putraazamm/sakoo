// lib/controllers/parent_dashboard_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sakoo/screens/welcome_screen.dart';
import 'package:sakoo/services/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/child_model.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';

class ParentDashboardController extends GetxController {
  final _supabase = Supabase.instance.client;

  var isLoading = true.obs;

  // Data asas parent
  var parentData = <String, dynamic>{}.obs;
  var parentName = "".obs;
  var parentBalance = 0.0.obs;

  // Data list
  var childrenList = <ChildModel>[].obs;
  var recentActivities = <TransactionModel>[].obs;

  // --- 1. CONTROLLER UNTUK FORM INPUT ANAK BARU ---
  final nameController = TextEditingController();
  final nicknameController = TextEditingController();
  final dobController = TextEditingController();
  final nricController = TextEditingController();
  final address1Controller = TextEditingController();
  final address2Controller = TextEditingController();
  final schoolController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    // if (Get.arguments != null) {
    //   parentData.value = Get.arguments as Map<String, dynamic>;

    //   print("=== Data Parent Dikutip Dari Arguments ===");
    //   print("Nama: ${parentName.value}");
    //   print("Baki: ${parentBalance.value}");
    // }
    _initSession();
  }

  Future<void> _initSession() async {
    if (Get.arguments != null && Get.arguments is Map) {
      parentData.value = Map<String, dynamic>.from(Get.arguments);
    } else {
      // cold boot - no arguments, load from disk
      final saved = await SessionService.loadSession();
      if (saved != null) {
        parentData.value = Map<String, dynamic>.from(saved);
      }
    }

    if (parentData['id'] == null) {
      await SessionService.clearSession();
      Get.offAll(() => const WelcomeScreen());
      return;
    }

    parentName.value = parentData['name'] ?? 'Parent';
    parentBalance.value = (parentData['balance'] ?? 0.0).toDouble();
    await fetchDashboardData();
  }

  // Future<void> _loadSessionIfNeeded() async {
  //   if (parentData.isEmpty) {
  //     final saved = await SessionService.loadSession();
  //     if (saved != null) {
  //       parentData.value = saved;
  //     }
  //   }
  //   parentName.value = parentData['name'] ?? 'Parent';
  //   parentBalance.value = (parentData['balance'] ?? 0.0).toDouble();
  //   fetchDashboardData();
  // }

  void logout() async {
    await SessionService.clearSession();
    parentData.clear();
    childrenList.clear();
    recentActivities.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    Get.offAll(() => const WelcomeScreen());
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;

      final parentId = parentData['id'];
      if (parentId == null) {
        throw Exception("Session Invalid.");
      }

      final parentDbData = await _supabase
          .from('user')
          .select('name, balance')
          .eq('id', parentId)
          .single();

      parentName.value = parentDbData['name'] ?? 'Parent';
      parentBalance.value = (parentDbData['balance'] ?? 0.0).toDouble();
      parentData['name'] = parentName.value;
      parentData['balance'] = parentBalance.value;

      final List<dynamic> childrenData = await _supabase
          .from('child')
          .select('*')
          .eq('parentId', parentId);
      childrenList.assignAll(
        childrenData.map((e) => ChildModel.fromJson(e)).toList(),
      );

      final List<dynamic> transactionData = await _supabase
          .from('transaction')
          .select('*, child(childName)')
          .eq('parentId', parentId)
          .order('createdAt', ascending: false)
          .limit(10);
      recentActivities.assignAll(
        transactionData.map((e) => TransactionModel.fromJson(e)).toList(),
      );

      await SessionService.saveSession(
        Map<String, dynamic>.from(parentData),
      ); // keep session cache fresh after every fetch
    } catch (e) {
      debugPrint('fetchDashboardData error: $e');
      Get.snackbar(
        "Database Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- DAFTAR ANAK (Menggunakan Text Controllers) ---
  Future<void> addNewChild() async {
    final parentId = parentData['id'];
    if (parentId == null) {
      Get.snackbar("Ralat", "Sesi tidak sah. Sila log masuk semula.");
      return;
    }

    if (nameController.text.trim().isEmpty ||
        nicknameController.text.trim().isEmpty) {
      Get.snackbar(
        "Sila Isi",
        "Nama penuh dan nama panggilan anak wajib diisi.",
      );
      return;
    }

    try {
      isLoading.value = true;
      String generatedChildId =
          'C-${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';

      // Hantar data input dari form terus ke Supabase table 'child'
      await _supabase.from('child').insert({
        'childId': generatedChildId,
        'parentId': parentId,
        'childName': nameController.text.trim(),
        'childNickname': nicknameController.text.trim(),
        'dob': dobController.text.trim(),
        'NRIC': int.tryParse(nricController.text.trim()) ?? 0,
        'address_line1': address1Controller.text.trim(),
        'address_line2': address2Controller.text.trim().isEmpty
            ? null
            : address2Controller.text.trim(),
        'childSchool': schoolController.text.trim(),
        'childBalance': 0.00,
        'dailyLimit': 0.00,
        'isActive': true,
        'cardId': '',
      });

      // Store nickname before disposing controllers
      String childNickname = nicknameController.text;

      await fetchDashboardData();
      clearFormFields();
      Get.back();

      Get.snackbar(
        "Successful",
        "$childNickname successfully registered!",
        backgroundColor: Colors.green.withOpacity(0.1),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        "Ralat",
        "Gagal mendaftar anak: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // function to update child's daily limit directly
  Future<void> updateDailyLimit(String childId, double newLimit) async {
    int index = childrenList.indexWhere(
      (element) => element.childId == childId,
    );
    if (index == -1) return;

    final oldChild = childrenList[index];

    try {
      childrenList[index] = oldChild.copyWith(dailyLimit: newLimit);

      await _supabase
          .from('child')
          .update({'dailyLimit': newLimit})
          .eq('childId', childId);

      Get.snackbar(
        "Successful!",
        "Daily Limit for ${oldChild.childName} is updated to RM $newLimit",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.1),
      );
    } catch (e) {
      childrenList[index] = oldChild;
      Get.snackbar(
        "Failed",
        "Failed to update daily limit to database: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // function: top up child account balance -> in future, put this part to child controller
  Future<void> topUpChildBalance(String childId, double amount) async {
    int index = childrenList.indexWhere(
      (element) => element.childId == childId,
    );
    if (index == -1) return;

    final oldChild = childrenList[index];
    double oldParentBalance = parentBalance.value;

    if (parentBalance.value < amount) {
      Get.snackbar(
        "Insufficient balance",
        "Please add funds at least RM $amount to your account first",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      final parentId = parentData['id'];
      if (parentId == null) throw Exception("Session ends.");

      parentBalance.value -= amount;
      parentData['balance'] = parentBalance.value;

      await _supabase.rpc(
        'top_up_child_balance_rpc',
        params: {
          'p_parent_id': parentId,
          'p_child_id': childId,
          'p_amount': amount,
        },
      );

      await fetchDashboardData();

      await _supabase.from('transaction').insert({
        'parentId': parentId,
        'childId': childId,
        'merchantName': 'Sakoo Card Top-Up',
        'category': 'Top-Up',
        'amount': amount,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      Get.snackbar(
        "Top-up successful!",
        "RM ${amount.toStringAsFixed(2)} is successfully credited to ${oldChild.childName}.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.1),
      );
    } catch (e) {
      parentBalance.value = oldParentBalance;
      parentData['balance'] = oldParentBalance;
      childrenList[index] = oldChild;
      Get.snackbar(
        "Error",
        "Failed to top up: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
      );
    }
  }

  // withdraw balance from child card to parent's wallet
  Future<void> withdrawChildBalance(String childId, double amount) async {
    int index = childrenList.indexWhere(
      (element) => element.childId == childId,
    );
    if (index == -1) return;

    final oldChild = childrenList[index];
    double oldParentBalance = parentBalance.value;

    // check if the child balance has enough funds
    if (oldChild.childBalance < amount) {
      Get.snackbar(
        "Insufficient Funds",
        "${oldChild.childNickname} only has RM ${oldChild.childBalance.toStringAsFixed(2)} available.",
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      final parentId = parentData['id'];
      if (parentId == null) throw Exception("Session ends.");

      // updates the UI first before data is uploaded to the DB
      parentBalance.value += amount;
      parentData['balance'] = parentBalance.value;

      double newChildBalance = oldChild.childBalance - amount;

      childrenList[index] = oldChild.copyWith(childBalance: newChildBalance);

      // update child table
      await _supabase
          .from('child')
          .update({'childBalance': newChildBalance})
          .eq('childId', childId);

      // update user table (parent)
      await _supabase
          .from('user')
          .update({'balance': parentBalance.value})
          .eq('id', parentId);

      // insert transaction record
      await _supabase.from('transaction').insert({
        'parentId': parentId,
        'childId': childId,
        'merchantName': 'Sakoo Card Withdrawal from ${oldChild.childNickname}',
        'category': 'Withdrawal',
        'amount': amount,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      await fetchDashboardData();

      Get.snackbar(
        "Withdrawal Successful!",
        "RM ${amount.toStringAsFixed(2)} has been withdrawn from ${oldChild.childNickname}.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.1),
      );
    } catch (e) {
      // rollback if anything falls
      parentBalance.value = oldParentBalance;
      parentData['balance'] = oldParentBalance;
      childrenList[index] = oldChild;

      Get.snackbar(
        "Error",
        "Failed to withdraw funds: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
      );
    }
  }

  // function: add funds to parent's own wallet
  Future<bool> addFundsToWallet(double amount) async {
    if (amount <= 0) {
      Get.snackbar("Error", "Please enter amount greater than 0");
      return false;
    }

    try {
      isLoading.value = true;
      final parentId = parentData['id'];
      if (parentId == null)
        throw Exception("Session ends. Please log in again.");

      double newParentBalance = parentBalance.value + amount;

      await _supabase
          .from('user')
          .update({'balance': newParentBalance})
          .eq('id', parentId);

      await _supabase.from('transaction').insert({
        'parentId': parentId,
        'childId': null,
        'merchantName': 'Bank Transfer (Add Funds)',
        'category': 'Top-Up',
        'amount': amount,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      parentBalance.value = newParentBalance;
      parentData['balance'] = newParentBalance;

      await fetchDashboardData();

      Get.snackbar(
        "Successful!",
        "RM ${amount.toStringAsFixed(2)} successfully credited to your wallet.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.1),
        margin: EdgeInsets.all(15),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        "Failed",
        "Failed to add funds. $e.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createSavingGoal(String title, double target) async {
    try {
      final parentId = parentData['id'];
      if (parentId == null) throw Exception("Sesi tamat.");

      if (childrenList.isEmpty) {
        Get.snackbar("Ralat", "Sila tambah anak terlebih dahulu.");
        return;
      }

      String selectedChildId = childrenList.first.childId;

      GoalModel newGoal = GoalModel(
        goalId: '',
        childId: selectedChildId,
        parentId: parentId,
        goalTitle: title,
        targetAmount: target,
        collectedAmount: 0.0,
      );

      Map<String, dynamic> goalData = newGoal.toJson();
      goalData.remove('goalId');

      await _supabase.from('goal').insert(goalData);

      Get.snackbar("Goal Added!", "New goal is added.");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  void clearFormFields() {
    nameController.clear();
    nicknameController.clear();
    dobController.clear();
    nricController.clear();
    address1Controller.clear();
    address2Controller.clear();
    schoolController.clear();
  }

  @override
  void onClose() {
    nameController.dispose();
    nicknameController.dispose();
    dobController.dispose();
    nricController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    schoolController.dispose();
    super.onClose();
  }
}
