import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<List<Map<String, dynamic>>> fetchOrderDataByAssignedTo() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? assignedId = prefs.getString('ID');

  if (assignedId == null) {
    throw 'No assigned ID found in SharedPreferences';
  }

  final DatabaseReference orderRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
  ).ref('orders');

  try {
    Query query = orderRef.orderByChild('assignedto').equalTo(assignedId);
    DatabaseEvent event = await query.once();

    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> data = event.snapshot.value as Map;
      if (data.isNotEmpty) {
        return List<Map<String, dynamic>>.from(data.values.map((item) => Map<String, dynamic>.from(item)));
      }
    }
    throw 'No order found for the assigned ID';
  } catch (e) {
    throw 'Error fetching order data: $e';
  }
}


Future<Map<String, dynamic>> fetchOrderDataByAssigned(
    String assignedToId) async {
  final DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref('orders');

  final DatabaseEvent snapshot = await databaseReference
      .orderByChild('assignedTo')
      .equalTo(assignedToId)
      .once();

  if (snapshot.snapshot.exists) {
    final Map<dynamic, dynamic> orderDataMap =
        snapshot.snapshot.value as Map<dynamic, dynamic>;

    final Map<String, dynamic> orderData =
        Map<String, dynamic>.from(orderDataMap);

    return orderData;
  } else {
    throw Exception('No order found for assigned ID: $assignedToId');
  }
}

