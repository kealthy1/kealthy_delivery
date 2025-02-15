import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_delivery/Pages/Cod_page.dart/Order_Confirm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Services/OrderService.dart';
import '../../Riverpod/NotificationService.dart';
import '../Order/OrderItem.dart';

final DeliverisLoadingProvider = StateProvider<bool>((ref) => false);

class DeliverNowButton extends ConsumerWidget {
  final Order order;

  const DeliverNowButton({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(DeliverisLoadingProvider);
    final isLoadingNotifier = ref.read(DeliverisLoadingProvider.notifier);
    final OrderService orderService = OrderService(
      'https://kealthy-90c55-dd236.firebaseio.com/',
    );
    final NotificationService notificationService =
        NotificationService.instance;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF273847),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              if (order.paymentmethod != 'Cash on Delivery') {
                await prefs.setString('paymentStatus', 'No');
              }

              showDialog(
                context: context,
                builder: (_) => _buildAlertLog(
                  context: context,
                  isLoadingNotifier: isLoadingNotifier,
                  orderService: orderService,
                  notificationService: notificationService,
                ),
              );
            },
            child: const Center(
              child: Text(
                'Delivered',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertLog({
    required BuildContext context,
    required StateController<bool> isLoadingNotifier,
    required OrderService orderService,
    required NotificationService notificationService,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final isLoading = ref.watch(DeliverisLoadingProvider);

        return AlertDialog(
          title: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF273847),
                  ),
                )
              : const Center(
                  child: Text(
                    "Delivery Confirmation",
                    style: TextStyle(fontSize: 25, fontFamily: "poppins"),
                  ),
                ),
          content: isLoading
              ? null
              : const Text(
                  "Do you want to mark this order delivered?",
                  style: TextStyle(fontFamily: "poppins"),
                ),
          actions: isLoading
              ? []
              : [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style:
                          TextStyle(color: Colors.black, fontFamily: "poppins"),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(DeliverisLoadingProvider.notifier).state = true;
                      _deliverOrder(
                        orderService,
                        notificationService,
                        order,
                        context,
                        ref.read(DeliverisLoadingProvider.notifier),
                      );
                    },
                    child: const Text(
                      'OK',
                      style:
                          TextStyle(color: Colors.black, fontFamily: "poppins"),
                    ),
                  ),
                ],
        );
      },
    );
  }

  void _deliverOrder(
    OrderService orderService,
    NotificationService notificationService,
    Order order,
    BuildContext context,
    StateController<bool> isLoadingNotifier,
  ) {
    unawaited(
      _updateOrderAndSendNotification(
        orderService,
        notificationService,
        order,
        context,
        isLoadingNotifier,
      ),
    );
  }

  Future<void> _updateOrderAndSendNotification(
    OrderService orderService,
    NotificationService notificationService,
    Order order,
    BuildContext context,
    StateController<bool> isLoadingNotifier,
  ) async {
    try {
      await orderService.updateOrderStatus(order.orderId, 'Order Delivered');
      try {
        await notificationService.sendNotification(
          fcmToken: order.fcmToken,
          title: 'Order Delivered',
          body: 'Delivery complete! Thank you for choosing us.',
        );
      } catch (notificationError) {
        print('Notification failed: $notificationError');
      }
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderNumber: order.orderId,
              totalAmount: order.totalAmountToPay,
              distance: order.distance,
              orderStatus: order.status,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      if (context.mounted) {
        isLoadingNotifier.state = false;
      }
    }
  }
}
