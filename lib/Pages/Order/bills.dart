import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'MyOrders.dart';

class BillPage extends StatelessWidget {
  final Order order;

  const BillPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Order Bill'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID: ${order.orderId}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "poppins"),
                ),
                Text(
                  '${order.distance} km',
                  style: const TextStyle(fontSize: 16, fontFamily: "poppins"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.person_alt_circle,
                      size: 25,
                      color: Colors.grey,
                    ),
                    Text(
                      ' ${order.name}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  '${order.date.day}-${order.date.month}-${order.date.year}',
                  style: const TextStyle(
                      fontFamily: "poppins",
                      fontSize: 16,
                      fontStyle: FontStyle.normal),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 2),
            Expanded(
              child: ListView.builder(
                itemCount: order.orderItems.length,
                itemBuilder: (context, index) {
                  final item = order.orderItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.itemName} (x${item.itemQuantity})',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          '₹${(item.itemPrice * item.itemQuantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(thickness: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: ₹${order.totalAmountToPay.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
