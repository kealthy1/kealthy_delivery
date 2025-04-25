import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Reusable.dart/Bottomsheet.dart';
import '../../Riverpod/NotificationService.dart';
import '../../Services/OrderService.dart';
import '../Deliver/Deliver.dart';
import '../Order/OrderItem.dart';

final isLoadingProvider = StateProvider<bool>((ref) => false);

class ReachNowButton extends ConsumerWidget {
  final Order order;

  const ReachNowButton({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    final isLoadingNotifier = ref.read(isLoadingProvider.notifier);

    final OrderService orderService = OrderService(
      'https://kealthy-90c55-dd236.firebaseio.com/',
    );
    final NotificationService notificationService =
        NotificationService.instance;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF273847),
                ),
              )
            : SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF273847),
                  ),
                  onPressed: () async {
                    ConfirmationBottomSheet.show(
                      context: context,
                      title: 'Confirm Action',
                      message: 'Are you sure you want to mark this order as reached?',
                      onConfirm: () async {
                        isLoadingNotifier.state = true;
                        await _handleMarkAsReached(context, ref, order, orderService, notificationService);
                      },
                      onCancel: () {
                        Navigator.pop(context); 
                      },
                    );
                  },
                  child: Center(
                    child: Text(
                      'Reached Drop',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ), 
              ),
      ),
    );
  }

  Future<void> _handleMarkAsReached(
    BuildContext context,
    WidgetRef ref,
    Order order,
    OrderService orderService,
    NotificationService notificationService,
  ) async {
    final isLoadingNotifier = ref.read(isLoadingProvider.notifier);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('paymentStatus');

    if (!context.mounted) return;

    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DeliverNow(order: order),
        ),
      );

      unawaited(
        orderService.updateOrderStatus(order.orderId, 'Order Reached'),
      );

      unawaited(
        notificationService.sendNotification(
          fcmToken: order.fcmToken,
          title: 'Order Reached',
          body:
              'Delivery Agent Reached at your location. Please connect to receive your order.',
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (context.mounted) {
        isLoadingNotifier.state = false;
      }
    }
  }
}
