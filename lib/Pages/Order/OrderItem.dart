import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

double _toDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? fallback;
  return fallback;
}

List<dynamic> _toList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v;
  if (v is Map) return v.values.toList();
  return [];
}

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
      name: data['Name']?.toString() ?? 'N/A',
      phoneNumber: data['phoneNumber']?.toString() ?? 'N/A',
      deliveryInstructions: data['deliveryInstructions']?.toString() ?? 'N/A',
      selectedDirections: data['selectedDirections']?.toString() ?? 'N/A',
      selectedRoad: data['selectedRoad']?.toString() ?? 'N/A',

      selectedLatitude: _toDouble(data['selectedLatitude']),
      selectedLongitude: _toDouble(data['selectedLongitude']),

      distance: data['distance']?.toString() ?? '0',
      paymentmethod: data['paymentmethod']?.toString() ?? 'Unknown',

      totalAmountToPay: _toDouble(data['totalAmountToPay']),

      fcmToken: data['fcm_token']?.toString() ?? '',
      status: data['status']?.toString() ?? 'Pending',

      orderItems: _toList(data['orderItems']),

      cookinginstrcutions: data['cookinginstrcutions']?.toString() ?? '',
      selectedSlot: data['selectedSlot']?.toString() ?? '',
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
  DatabaseReference databaseRef =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/",
      ).ref();
  return OrderNotifier(databaseRef);
});

final showAllItemsProvider = StateProvider<bool>((ref) => false);
