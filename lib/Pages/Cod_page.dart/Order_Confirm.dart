import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:kealthy_delivery/Pages/Cod_page.dart/COD.dart';
import 'package:kealthy_delivery/Pages/LandingPages/SearchOrders.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Deliver/Deliver_Button.dart';

final orderServiceProvider = Provider<OrderServicesucces>(
  (ref) => OrderServicesucces(),
);

final isLoadingProvider = StateProvider<bool>((ref) => false);

class OrderServicesucces {
  void updateOrderStatus(String orderId, String status) {
    unawaited(_updateOrderStatus(orderId, status));
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    DatabaseReference databaseRef =
        FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/",
        ).ref();

    try {
      final snapshot = await databaseRef.child('orders').once();
      if (snapshot.snapshot.exists) {
        Map<dynamic, dynamic> orders =
            snapshot.snapshot.value as Map<dynamic, dynamic>;
        List<MapEntry<dynamic, dynamic>> deliveredOrders =
            orders.entries
                .where((entry) => entry.value['status'] == 'Order Delivered')
                .toList();

        for (var deliveredOrder in deliveredOrders) {
          final currentDateTime = DateTime.now();
          final formattedDate =
              "${currentDateTime.day.toString().padLeft(2, '0')}"
              "-${currentDateTime.month.toString().padLeft(2, '0')}"
              "-${currentDateTime.year}";

          final formattedTime =
              "${currentDateTime.hour.toString().padLeft(2, '0')}:"
              "${currentDateTime.minute.toString().padLeft(2, '0')}:"
              "${currentDateTime.second.toString().padLeft(2, '0')}";
          final prefs = await SharedPreferences.getInstance();
          print('deliveredOrder--${deliveredOrder.value['orderItems']}');
          final Cod = prefs.getString('paymentStatus');
          final orderData = {
            'phoneNumber': deliveredOrder.value['phoneNumber'],
            'orderId': deliveredOrder.key,
            'assignedTo': deliveredOrder.value['assignedto'],
            'fcm': deliveredOrder.value['fcm_token'],
            'orderItems': deliveredOrder.value['orderItems'],
            'Name': deliveredOrder.value['Name'],
            'totalAmountToPay': deliveredOrder.value['totalAmountToPay'],
            'selectedLatitude': deliveredOrder.value['selectedLatitude'],
            'selectedLongitude': deliveredOrder.value['selectedLongitude'],
            'date': formattedDate,
            'time': formattedTime,
            'ReceivedCOD': Cod?.isNotEmpty == true ? Cod : 'Yes',
            'preferredTime': deliveredOrder.value['preferredTime'] ?? '0',
            'orderPlacedAt': deliveredOrder.value['createdAt'],
            'Type': deliveredOrder.value['type'],
          };

          const String apiUrl =
              "https://kealthy-backend-3.onrender.com/api/orders/create-order";
          print('api body--${jsonEncode(orderData)}');

          unawaited(
            http
                .post(
                  Uri.parse(apiUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(orderData),
                )
                .then((response) {
                  if (response.statusCode == 201 ||
                      response.statusCode == 200) {
                    print('Order successfully sent to API.');
                    unawaited(
                      databaseRef
                          .child('orders')
                          .child(deliveredOrder.key)
                          .remove(),
                    );
                  } else {
                    print('Failed to send order to API: ${response.body}');
                  }
                })
                .catchError((error) {
                  print('HTTP Request Error: $error');
                }),
          );
        }
      } else {
        print('No orders found in the database.');
      }
    } catch (error) {
      print('Error updating order status: $error');
    }
  }
}

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderNumber;
  final double totalAmount;
  final String distance;
  final String orderStatus;

  const OrderConfirmationScreen({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
    required this.distance,
    required this.orderStatus,
  });

  @override
  _OrderConfirmationScreenState createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: unused_result
      ref.refresh(paymentProvider);
      ref
          .read(orderServiceProvider)
          .updateOrderStatus(widget.orderNumber, 'Order Delivered');
    });
  }

  void _onHomeButtonPressed(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnlinePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: screenHeight * 0.1),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF273847),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Order Delivered!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF273847),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'GREAT JOB YOU ARE ON TIME 👍🏻',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF273847),
                        fontFamily: "poppins",
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        infoRow(
                          icon: Icons.assignment,
                          label: 'Order ID:',
                          value:
                              widget.orderNumber.length > 6
                                  ? widget.orderNumber.substring(
                                    widget.orderNumber.length - 10,
                                  )
                                  : widget.orderNumber,
                          iconColor: Colors.black87,
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        infoRow(
                          icon: Icons.location_on,
                          label: 'Distance:',
                          value: '${widget.distance} km',
                          iconColor: Colors.red,
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        infoRow(
                          icon: Icons.currency_rupee,
                          label: 'Total Amount:',
                          value: '₹${widget.totalAmount.toStringAsFixed(0)} /-',
                          iconColor: const Color(0xFF273847),
                        ),
                        const Divider(),
                      ],
                    ),
                  ],
                ),
              ),
              isLoading
                  ? const CircularProgressIndicator(color: Colors.red)
                  : SafeArea(
                    child: SizedBox(
                      width: screenWidth * 0.9,
                      child: ElevatedButton(
                        onPressed: () {
                          // ignore: unused_result
                          ref.refresh(isLoadingProvider);
                          // ignore: unused_result
                          ref.refresh(DeliverisLoadingProvider);
                          _onHomeButtonPressed(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF273847),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Get Next Order',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
}

Widget infoRow({
  required IconData icon,
  required String label,
  required String value,
  required Color iconColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontFamily: "poppins",
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontFamily: "poppins",
          ),
        ),
      ],
    ),
  );
}
