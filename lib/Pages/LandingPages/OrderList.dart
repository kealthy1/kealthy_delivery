import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_delivery/Pages/Pick/PickOrder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Riverpod/Loading.dart';
import '../../Services/Location_off_exit.dart';
import '../Deliver/Deliver.dart';
import '../Order/OrderItem.dart';
import '../Reach/Mark_Reached.dart';

class OrdersAssignedPage extends ConsumerStatefulWidget {
  const OrdersAssignedPage({super.key});

  @override
  _OrdersAssignedPageState createState() => _OrdersAssignedPageState();
}

class _OrdersAssignedPageState extends ConsumerState<OrdersAssignedPage> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    _ordersFuture = fetchOrderDataByAssignedTo();
  }

  @override
  Widget build(BuildContext context) {
    Future.microtask(() async {
      await ref
          .read(locationServiceProvider.notifier)
          .checkLocationAndShowAlert(context);
    });
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Assigned Orders', style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingWidget(message: 'Loading Orders...'),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No orders assigned',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            );
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('paymentStatus');
                  try {
                    final DatabaseReference orderRef =
                        FirebaseDatabase.instanceFor(
                          app: Firebase.app(),
                          databaseURL:
                              'https://kealthy-90c55-dd236.firebaseio.com/',
                        ).ref('orders/${order.orderId}');
                    DatabaseEvent event = await orderRef.once();

                    if (event.snapshot.value != null) {
                      final updatedOrderData = Map<String, dynamic>.from(
                        event.snapshot.value as Map<dynamic, dynamic>,
                      );
                      final updatedOrder = Order.fromMap(
                        order.orderId,
                        updatedOrderData,
                      );
                      if (updatedOrder.status == 'Order Reached') {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder:
                                (context) => DeliverNow(order: updatedOrder),
                          ),
                        );
                      } else if (updatedOrder.status == 'Order Picked') {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder:
                                (context) =>
                                    ReachNow(orderId: updatedOrder.orderId),
                          ),
                        );
                      } else if (updatedOrder.status == 'Order Placed') {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder:
                                (context) =>
                                    pickorder(orderId: updatedOrder.orderId),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder:
                                (context) => DeliverNow(order: updatedOrder),
                          ),
                        );
                      }
                    } else {
                      throw 'Order data not found';
                    }
                  } catch (e) {
                    print('Error navigating based on order: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error fetching order details: $e'),
                      ),
                    );
                  }
                },
                child: _buildOrderTile(order),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderTile(Order order) {
    return Card(
      color: const Color(0xFF273847),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order: ${order.orderId.length > 6 ? order.orderId.substring(order.orderId.length - 10) : order.orderId}",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                ),
                Text(
                  '${order.distance} km',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.selectedSlot,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(order.name, style: GoogleFonts.poppins(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              order.selectedRoad,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Order>> fetchOrderDataByAssignedTo() async {
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
          return data.entries
              .map(
                (entry) => Order.fromMap(
                  entry.key,
                  Map<dynamic, dynamic>.from(entry.value),
                ),
              )
              .toList();
        }
      }
      throw 'No order found for the assigned ID';
    } catch (e) {
      throw 'Error fetching order data: $e';
    }
  }
}
