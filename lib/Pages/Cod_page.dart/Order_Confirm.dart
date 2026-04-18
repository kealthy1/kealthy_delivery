import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:kealthy_delivery/Pages/Cod_page.dart/COD.dart';
import 'package:kealthy_delivery/Pages/LandingPages/SearchOrders.dart';
import '../Deliver/Deliver_Button.dart';

final orderServiceProvider = Provider<OrderServicesucces>(
  (ref) => OrderServicesucces(),
);

final isLoadingProvider = StateProvider<bool>((ref) => false);

class OrderServicesucces {
  Future<void> deliverOrderAndSync(
    BuildContext context,
    String targetOrderId,
  ) async {
    final databaseRef =
        FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/",
        ).ref();

    try {
      final snapshot = await databaseRef.child('orders/$targetOrderId').get();

      if (!snapshot.exists || snapshot.value == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Order not found')));
        }
        return;
      }

      final order = Map<String, dynamic>.from(snapshot.value as Map);

      final String address =
          (order['selectedRoad']?.toString().isNotEmpty ?? false)
              ? order['selectedRoad'].toString()
              : await reverseLookupUsingPlaces(
                double.tryParse(order['selectedLatitude'].toString()) ?? 0,
                double.tryParse(order['selectedLongitude'].toString()) ?? 0,
              );

      final now = DateTime.now();
      final formattedDate =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      final formattedTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      final paymentMethod = (order['paymentmethod'] ?? '').toString();

      final orderData = {
        'phoneNumber': order['phoneNumber'],
        'orderId': targetOrderId,
        'assignedTo': order['assignedto'],
        'address': address,
        'distance': order['distance'],
        'fcm': order['fcm_token'],
        'orderItems': order['orderItems'],
        'Name': order['Name'],
        'totalAmountToPay': order['totalAmountToPay'],
        'selectedLatitude': order['selectedLatitude'],
        'selectedLongitude': order['selectedLongitude'],
        'date': formattedDate,
        'time': formattedTime,
        'ReceivedCOD': paymentMethod == 'Cash on Delivery' ? 'Yes' : 'No',
        'preferredTime': order['preferredTime'] ?? '0',
        'orderPlacedAt': order['createdAt'],
        'Type': order['type'],
        'paymentType': paymentMethod == 'Cash on Delivery' ? 'COD' : 'Online',
        'paymentGateway': null,
        'paymentLastSix': null,
        'paymentReceived': true,
        'deliveredAt': now.toIso8601String(),
      };

      const apiUrl =
          "https://api-jfnhkjk4nq-uc.a.run.app/delivered/create-order";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await databaseRef.child('orders/$targetOrderId').remove();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Order delivered successfully'),
            ),
          );
        }
      } else {
        debugPrint(
          'API failed for $targetOrderId → ${response.statusCode} | ${response.body}',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Delivery sync failed')));
        }
      }
    } catch (e, st) {
      debugPrint('Delivery error: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order sync failed')));
      }
    }
  }

  Future<String> reverseLookupUsingPlaces(double lat, double lng) async {
    final apiKey = "AIzaSyBVG3TySuO7MPp5yNuXaR5sSAODynVsKJ4";

    final url = Uri.parse(
      'https://places.googleapis.com/v1/places:searchNearby',
    );

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'places.formattedAddress,places.displayName',
        },
        body: jsonEncode({
          "locationRestriction": {
            "circle": {
              "center": {"latitude": lat, "longitude": lng},
              "radius": 50.0,
            },
          },
        }),
      );

      if (res.statusCode != 200) {
        return 'Address not found';
      }

      final data = jsonDecode(res.body);

      if (data['places'] == null || data['places'].isEmpty) {
        return 'Address not found';
      }

      return data['places'][0]['formattedAddress'] ?? 'Address not found';
    } catch (e) {
      return 'Address not found';
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      ref.read(isLoadingProvider.notifier).state = true;

      try {
        await ref
            .read(orderServiceProvider)
            .deliverOrderAndSync(context, widget.orderNumber);
      } finally {
        if (mounted) {
          ref.read(isLoadingProvider.notifier).state = false;
        }
      }
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
                          ref.invalidate(isLoadingProvider);
                          ref.invalidate(DeliverisLoadingProvider);
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
