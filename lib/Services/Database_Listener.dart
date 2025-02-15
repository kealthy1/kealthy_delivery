import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm.dart'; // Import your notification service

class DatabaseListener {
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kealthy-90c55-dd236.firebaseio.com/', // Make sure this URL is correct
  );

  void listenForOrderStatusChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final String? assignedId =
        prefs.getString('ID'); // Get assigned ID from SharedPreferences

    if (assignedId == null) {
      return; // No assigned ID found
    }

    final ordersRef = _database.ref('orders'); // Reference to the 'orders' node

    // Listen for changes in the 'orders' node
    ordersRef.onChildChanged.listen((event) {
      final data =
          event.snapshot.value as Map<dynamic, dynamic>?; // Get the data

      // Check if the relevant fields exist in the data
      if (data != null &&
          data.containsKey('status') &&
          data.containsKey('assignedto')) {
        // If the order is assigned to the current user, proceed
        if (data['assignedto'] == assignedId) {
          final status = data['status'] ??
              "Unknown"; // Get the status (default to "Unknown")

          String notificationTitle = "Order Update";
          String notificationBody;

          // Define the notification message based on the order status
          switch (status) {
            case "Order Packed":
              notificationTitle = "Pick Order Now";
              notificationBody = "Order Marked As Ready";
              break;

            default:
              notificationBody = "Order status updated to: $status.";
          }

          // Show the notification
          NotificationService.instance.showNotification(
            title: notificationTitle,
            body: notificationBody,
          );
        }
      }
    });
  }
}
