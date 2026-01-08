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

class PaymentDialogResult {
  final String paymentType; // "COD" | "Online"
  final String? paymentGateway; // "Razorpay" | "Stripe" ... (optional)
  final String paymentLastSix; // optional (for card/upi ref)
  final bool paymentReceived; // true/false
  final String receivedCOD; // "Yes" | "No" (keeps your existing field)

  const PaymentDialogResult({
    required this.paymentType,
    required this.paymentGateway,
    required this.paymentLastSix,
    required this.paymentReceived,
    required this.receivedCOD,
  });
}

final isLoadingProvider = StateProvider<bool>((ref) => false);
Future<PaymentDialogResult?> showPaymentStatusDialog(
  BuildContext context, {
  String title = 'Payment Status',
}) async {
  String paymentType = 'COD';
  bool paymentReceived = true;
  String? gateway;
  final lastSixCtrl = TextEditingController();

  return showDialog<PaymentDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Payment Type
                  DropdownButtonFormField<String>(
                    value: paymentType,
                    items: const [
                      DropdownMenuItem(value: 'COD', child: Text('COD')),
                      DropdownMenuItem(value: 'Online', child: Text('Online')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => paymentType = v);
                      if (v == 'COD') {
                        setState(() {
                          gateway = null;
                          lastSixCtrl.clear();
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Payment Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Gateway (only for Online)
                  if (paymentType == 'Online')
                    DropdownButtonFormField<String>(
                      value: gateway,
                      items: const [
                        DropdownMenuItem(
                          value: 'Razorpay',
                          child: Text('Razorpay'),
                        ),
                        DropdownMenuItem(
                          value: 'Stripe',
                          child: Text('Stripe'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => gateway = v),
                      decoration: const InputDecoration(
                        labelText: 'Payment Gateway',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                    ),

                  if (paymentType == 'Online') const SizedBox(height: 12),

                  // Last 6 digits / ref (optional)
                  TextField(
                    controller: lastSixCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Last 6 digits / Ref (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers_outlined),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Payment received switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Payment received'),
                    value: paymentReceived,
                    onChanged: (v) => setState(() => paymentReceived = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  // Keep your existing SharedPreferences usage for COD status
                  // (this is what you were reading as "paymentStatus")
                  final prefs = await SharedPreferences.getInstance();
                  final codValue =
                      paymentType == 'COD'
                          ? (paymentReceived ? 'Yes' : 'No')
                          : 'Yes'; // for Online you can keep Yes or ignore

                  await prefs.setString('paymentStatus', codValue);

                  Navigator.pop(
                    ctx,
                    PaymentDialogResult(
                      paymentType: paymentType,
                      paymentGateway: paymentType == 'Online' ? gateway : null,
                      paymentLastSix: lastSixCtrl.text.trim(),
                      paymentReceived: paymentReceived,
                      receivedCOD: codValue,
                    ),
                  );
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}

class OrderServicesucces {
  Future<void> updateOrderStatus(
    BuildContext context,
    PaymentDialogResult payment,
  ) async {
    await deliverMultipleOrdersAndSync(context, payment);
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

  Future<void> deliverMultipleOrdersAndSync(
    BuildContext context,
    PaymentDialogResult payment,
  ) async {
    final databaseRef =
        FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/",
        ).ref();

    try {
      final snapshot = await databaseRef.child('orders').get();
      if (!snapshot.exists) {
        debugPrint('No orders found.');
        return;
      }

      final Map<dynamic, dynamic> orders = Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final deliveredOrders =
          orders.entries
              .where(
                (e) =>
                    (e.value['status']?.toString() ?? '') == 'Order Delivered',
              )
              .toList();

      if (deliveredOrders.isEmpty) return;

      for (final entry in deliveredOrders) {
        final orderId = entry.key;
        final order = Map<String, dynamic>.from(entry.value);

        // 1️⃣ Ask payment details PER ORDER

        // 2️⃣ Address resolution
        final String address =
            (order['selectedRoad']?.toString().isNotEmpty ?? false)
                ? order['selectedRoad']
                : await reverseLookupUsingPlaces(
                  double.parse(order['selectedLatitude'].toString()),
                  double.parse(order['selectedLongitude'].toString()),
                );

        // 3️⃣ Date & Time
        final now = DateTime.now();
        final formattedDate =
            "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
        final formattedTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

        // 4️⃣ Build API payload (MATCHED STRUCTURE)
        final orderData = {
          'phoneNumber': order['phoneNumber'],
          'orderId': orderId,
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
          'ReceivedCOD': payment.paymentType == 'COD' ? 'Yes' : 'No',
          'preferredTime': order['preferredTime'] ?? '0',
          'orderPlacedAt': order['createdAt'],
          'Type': order['type'],
          'paymentType': payment.paymentType,
          'paymentGateway':
              payment.paymentType == 'Online' ? payment.paymentGateway : null,
          'paymentLastSix':
              payment.paymentLastSix.isNotEmpty ? payment.paymentLastSix : null,
          'paymentReceived': payment.paymentReceived,
          'deliveredAt': now.toIso8601String(),
        };

        const apiUrl =
            "https://api-jfnhkjk4nq-uc.a.run.app/delivered/create-order";

        // 5️⃣ Send to API
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(orderData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await databaseRef.child('orders/$orderId').remove();

          debugPrint('Order $orderId synced & removed.');
        } else {
          debugPrint(
            'API failed for $orderId → ${response.statusCode} | ${response.body}',
          );
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Delivered orders synced successfully'),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Multi-delivery error: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order sync failed')));
      }
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
      _openCodPopup();
      ref.refresh(paymentProvider);
    });
  }

  Future<void> _openCodPopup() async {
    final payment = await showPaymentStatusDialog(
      context,
      title: 'Payment Status • Order ${widget.orderNumber}',
    );

    if (payment == null) return;

    // Optional: store locally if needed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paymentStatus', payment.receivedCOD);

    // Now call backend sync
    await ref.read(orderServiceProvider).updateOrderStatus(context, payment);
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
