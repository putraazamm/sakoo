import 'package:get/get.dart';
// import 'merchant_dashboard_controller.dart'; 
import '../screens/merchant/merchant_checkout_page.dart';

class MerchantNewOrderController extends GetxController {
  // 1. Data Dummy Menu (Nanti boleh buat fungsi fetch dari table 'menu' di Supabase)
  var menuItems = [
    {'id': 1, 'name': 'Nasi Goreng Ayam', 'price': 6.50},
    {'id': 2, 'name': 'Mee Kari', 'price': 5.00},
    {'id': 3, 'name': 'Ayam Goreng', 'price': 3.50},
    {'id': 4, 'name': 'Teh O Ais', 'price': 1.50},
    {'id': 5, 'name': 'Milo Ais', 'price': 2.50},
    {'id': 6, 'name': 'Air Mineral', 'price': 1.00},
  ].obs;

  // 2. State untuk simpan Kuantiti Pesanan -> {id_makanan: kuantiti}
  var cart = <int, int>{}.obs;

  // 3. Getter untuk kira Jumlah Keseluruhan (Total RM) secara automatik
  double get totalPrice {
    double total = 0.0;
    for (var item in menuItems) {
      int id = item['id'] as int;
      double price = item['price'] as double;
      int quantity = cart[id] ?? 0;
      total += price * quantity;
    }
    return total;
  }

  // Fungsi Tambah (+)
  void increment(int id) {
    cart[id] = (cart[id] ?? 0) + 1;
  }

  // Fungsi Tolak (-)
  void decrement(int id) {
    if (cart.containsKey(id) && cart[id]! > 0) {
      cart[id] = cart[id]! - 1;
    }
  }

  // Fungsi apabila butang 'Next >' ditekan
  void proceedToPayment() {
    if (totalPrice == 0) {
      Get.snackbar("No order", "Please at least add one item.");
      return;
    }

    List<Map<String, dynamic>> orderedItems = [];
    for (var item in menuItems) {
      int id = item['id'] as int;
      int quantity = cart[id] ?? 0;
      if (quantity > 0) {
        orderedItems.add({
          'id': id,
          'name': item['name'],
          'price': item['price'],
          'quantity': quantity,
          'subtotal': (item['price'] as double) * quantity,
        });
      }
    }
   Get.to(() => MerchantCheckoutScreen(), arguments: {'items': orderedItems, 'total': totalPrice});
  }
}
