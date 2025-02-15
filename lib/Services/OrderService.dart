import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  final DatabaseReference ordersRef;

  OrderService(String databaseUrl)
      : ordersRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: databaseUrl,
        ).ref('orders');

  Future<void> updateOrderStatus(String orderId, String status) async {
    final DatabaseReference orderRef = ordersRef.child(orderId);

    try {
      await orderRef.update({'status': status});
      print("Order status updated successfully to: $status");
    } catch (error) {
      print("Failed to update order status: $error");
    }
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? id = prefs.getString('ID');

    if (id == null) {
      print("No 'ID' found in SharedPreferences.");
      return [];
    }
    Query query = ordersRef.orderByChild('assignedto').equalTo(id);
    final DatabaseEvent event = await query.once();
    final List<Map<String, dynamic>> orders = [];

    if (event.snapshot.exists) {
      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        orders.add({'id': key, ...value});
      });
    } else {
      print("No orders found for assignedTo = $id");
    }

    return orders;
  }



  


}
