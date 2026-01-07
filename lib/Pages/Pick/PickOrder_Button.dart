import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Reusable.dart/Bottomsheet.dart';
import '../../Riverpod/NotificationService.dart';
import '../../Services/OrderService.dart';
import '../Order/OrderItem.dart';
import '../Reach/Mark_Reached.dart';

final isLoadingProvider = StateProvider<bool>((ref) => false);

class PickButton extends ConsumerWidget {
  final Order order;

  const PickButton({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF273847),
              ),
              onPressed:
                  isLoading
                      ? null
                      : () {
                        ConfirmationBottomSheet.show(
                          context: context,
                          title: 'Confirm Pick Order',
                          message: 'Are you sure you want to pick this order?',
                          onConfirm: () async {
                            await _handlePickOrder(context, ref, order);
                          },
                          onCancel: () {
                            Navigator.pop(context);
                          },
                        );
                      },
              child: Center(
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Pick Order',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePickOrder(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) async {
    final isLoadingNotifier = ref.read(isLoadingProvider.notifier);
    final OrderService orderService = OrderService(
      'https://kealthy-90c55-dd236.firebaseio.com/',
    );
    final NotificationService notificationService =
        NotificationService.instance;

    if (!context.mounted) return;

    try {
      isLoadingNotifier.state = true;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ReachNow(orderId: order.orderId),
        ),
      );

      unawaited(orderService.updateOrderStatus(order.orderId, 'Order Picked'));

      unawaited(
        notificationService.sendNotification(
          fcmToken: order.fcmToken,
          title: 'Order Picked',
          body:
              'Your order has been picked up and is now on its way to your doorstep! 🚚✨',
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (context.mounted) {
        isLoadingNotifier.state = false;
      }
    }
  }
}
