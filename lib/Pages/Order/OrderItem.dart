import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Order {
  final String orderId;
  final String name;
  final String phoneNumber;
  final String deliveryInstructions;
  final String selectedDirections;
  final String selectedRoad;
  final double selectedLatitude;
  final double selectedLongitude;
  final String distance;
  final String paymentmethod;
  final double totalAmountToPay;
  final String fcmToken;
  final String status;
  final String cookinginstrcutions;
  final String selectedSlot;
  final List<dynamic> orderItems;

  Order({
    required this.orderId,
    required this.name,
    required this.phoneNumber,
    required this.deliveryInstructions,
    required this.selectedDirections,
    required this.selectedRoad,
    required this.selectedLatitude,
    required this.selectedLongitude,
    required this.distance,
    required this.paymentmethod,
    required this.totalAmountToPay,
    required this.fcmToken,
    required this.status,
    required this.orderItems,
    required this.cookinginstrcutions,
    required this.selectedSlot,

  });

  factory Order.fromMap(String orderId, Map<dynamic, dynamic> data) {
    return Order(
      orderId: orderId,
      name: data['Name'] ?? 'N/A',
      phoneNumber: data['phoneNumber'] ?? 'N/A',
      deliveryInstructions: data['deliveryInstructions'] ?? 'N/A',
      selectedDirections: data['selectedDirections'] ?? 'N/A',
      selectedRoad: data['selectedRoad'] ?? 'N/A',
      selectedLatitude: (data['selectedLatitude'] as num).toDouble(),
      selectedLongitude: (data['selectedLongitude'] as num).toDouble(),
      distance: data['distance'] ?? '0',
      paymentmethod: data['paymentmethod'] ?? 'Unknown',
      totalAmountToPay: (data['totalAmountToPay'] as num).toDouble(),
      fcmToken: data['fcm_token'] ?? '',
      status: data['status'] ?? 'Pending',
      orderItems: List<dynamic>.from(data['orderItems'] ?? []),
      cookinginstrcutions:data["cookinginstrcutions"] ?? "",
      selectedSlot:data["selectedSlot"] ?? ""
    );
  }
}

class OrderNotifier extends StateNotifier<Order?> {
  final DatabaseReference databaseRef;

  OrderNotifier(this.databaseRef) : super(null);

  Future<void> fetchOrderDetails(String orderId) async {
    try {
      DatabaseReference orderRef = databaseRef.child('orders/$orderId');
      final snapshot = await orderRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        state = Order.fromMap(orderId, data);
      } else {
        throw Exception('Order not found');
      }
    } catch (e) {
      print('Error fetching order details: $e');
      state = null;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, Order?>((ref) {
  DatabaseReference databaseRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/")
      .ref();
  return OrderNotifier(databaseRef);
});

final showAllItemsProvider = StateProvider<bool>((ref) => false);
