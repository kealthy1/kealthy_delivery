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
    _ordersFuture = fetchOrderDataByAssignedTo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(locationServiceProvider.notifier)
          .checkLocationAndShowAlert(context);
    });
  }

  Future<void> _handleOrderTap(Order order) async {
    final prefs = await SharedPreferences.getInstance();

    // Clear old payment status before starting new flow
    await prefs.remove('paymentStatus');

    // Show a loading dialog so the user knows the app is fetching details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final DatabaseReference orderRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
      ).ref('orders/${order.orderId}');

      DatabaseEvent event = await orderRef.once();

      // Close the loading dialog
      if (mounted) Navigator.pop(context);

      if (event.snapshot.value != null) {
        final updatedOrderData = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );

        final updatedOrder = Order.fromMap(order.orderId, updatedOrderData);

        // Navigate based on status
        _navigateBasedOnStatus(updatedOrder);
      } else {
        _showSnackBar('Order no longer exists.');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loader on error
      debugPrint('Error navigating: $e');
      _showSnackBar('Error fetching order details: $e');
    }
  }

  void _navigateBasedOnStatus(Order updatedOrder) {
    Widget targetPage;

    switch (updatedOrder.status) {
      case 'Order Reached':
        targetPage = DeliverNow(order: updatedOrder);
        break;
      case 'Order Picked':
        targetPage = ReachNow(orderId: updatedOrder.orderId);
        break;
      case 'Order Placed':
        targetPage = pickorder(orderId: updatedOrder.orderId);
        break;
      default:
        // Fallback for any other status
        targetPage = DeliverNow(order: updatedOrder);
    }

    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => targetPage),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Assigned Orders', style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _ordersFuture = fetchOrderDataByAssignedTo();
          });
        },
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: LoadingWidget(message: 'Checking for orders...'),
              );
            }

            // If there is a legitimate error (e.g., no internet)
            if (snapshot.hasError) {
              return _buildEmptyState(
                icon: Icons.error_outline,
                message: 'Something went wrong. Pull to refresh.',
              );
            }

            // If the list is null or empty
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(
                icon: Icons.assignment_late_outlined,
                message: 'No orders assigned to you yet.',
              );
            }

            final orders = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return GestureDetector(
                  onTap:
                      () => _handleOrderTap(order), // Moved logic to a helper
                  child: _buildOrderTile(order),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Helper Widget for No Orders
  Widget _buildEmptyState({required IconData icon, required String message}) {
    return ListView(
      // Used ListView so RefreshIndicator works
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(icon, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Pull down to refresh",
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
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
      // Return empty rather than throwing to avoid the "Error" UI state
      return [];
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
        return data.entries
            .map(
              (entry) => Order.fromMap(
                entry.key,
                Map<dynamic, dynamic>.from(entry.value),
              ),
            )
            .toList();
      }

      // If snapshot is null, return empty list
      return [];
    } catch (e) {
      print('Error fetching order data: $e');
      // Still return empty list or handle specific errors here
      return [];
    }
  }
}
