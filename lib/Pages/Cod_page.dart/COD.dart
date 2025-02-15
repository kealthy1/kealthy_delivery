import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Order/OrderItem.dart';

class PaymentState {
  final bool isCaptured;
  final bool isLoading;
  final bool isCreatingQRCode;
  final bool isCheckingStatus;
  final String orderId;
  final String qrCodeUrl;

  PaymentState({
    required this.isCaptured,
    this.isLoading = false,
    this.isCreatingQRCode = false,
    this.isCheckingStatus = false,
    this.orderId = '',
    this.qrCodeUrl = '',
  });

  PaymentState copyWith({
    bool? isCaptured,
    bool? isLoading,
    bool? isCreatingQRCode,
    bool? isCheckingStatus,
    String? orderId,
    String? qrCodeUrl,
  }) {
    return PaymentState(
      isCaptured: isCaptured ?? this.isCaptured,
      isLoading: isLoading ?? this.isLoading,
      isCreatingQRCode: isCreatingQRCode ?? this.isCreatingQRCode,
      isCheckingStatus: isCheckingStatus ?? this.isCheckingStatus,
      orderId: orderId ?? this.orderId,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier()
      : super(PaymentState(
          isCaptured: false,
        ));

  Future<void> loadQRCodeDataFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderId = prefs.getString('orderId') ?? '';
      final qrCodeUrl = prefs.getString('qrCodeUrl') ?? '';
      state = state.copyWith(orderId: orderId, qrCodeUrl: qrCodeUrl);
    } catch (e) {
      print('Error loading data from shared preferences: $e');
    }
  }

  Future<void> createQRCode(double amount) async {
    try {
      state = state.copyWith(isCreatingQRCode: true);
      final response = await http.post(
        Uri.parse('https://api-jfnhkjk4nq-uc.a.run.app/create-qr-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'payment_amount': amount}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);

        if (decodedResponse['success'] == true &&
            decodedResponse['data'] != null) {
          final qrCodeId = decodedResponse['data']['id'];
          final qrCodeUrl = decodedResponse['data']['qrCodeUrl'];
          final orderId = decodedResponse['data']['orderId'];

          if (qrCodeId != null && qrCodeUrl != null && orderId != null) {
            await _saveToSharedPreferences(orderId, qrCodeUrl);
            state = state.copyWith(
              orderId: orderId,
              qrCodeUrl: qrCodeUrl,
              isCreatingQRCode: false,
            );
            print('QR Code created successfully with ID: $qrCodeId');
          } else {
            state = state.copyWith(isCreatingQRCode: false);
            print(
                'Error: QR code ID, URL, or order ID is missing in the response data');
          }
        } else {
          state = state.copyWith(isCreatingQRCode: false);
          final errorMessage =
              decodedResponse['message'] ?? 'Unknown error occurred';
          print('Error: $errorMessage');
        }
      } else {
        state = state.copyWith(isCreatingQRCode: false);
        print(
            'Failed to create QR code. Status code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      state = state.copyWith(isCreatingQRCode: false);
      print('Error while creating QR code: $e');
    }
  }

  Future<void> _saveToSharedPreferences(
      String orderId, String qrCodeUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('orderId', orderId);
      await prefs.setString('qrCodeUrl', qrCodeUrl);
      print('Successfully saved orderId and qrCodeUrl to shared preferences');
    } catch (e) {
      print(orderId);
      print(qrCodeUrl);
      print('Error saving data to shared preferences: $e');
    }
  }

  Future<void> checkPaymentStatus(String orderId) async {
    try {
      state = state.copyWith(isCheckingStatus: true);
      final response = await http.get(
        Uri.parse('https://api-jfnhkjk4nq-uc.a.run.app/payment/order/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data != null &&
            data['success'] == true &&
            data['payments'] != null &&
            data['payments'].isNotEmpty) {
          state = state.copyWith(
            isCaptured: true,
            isCheckingStatus: false,
          );
          print('Payments found for Order ID: $orderId');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('paymentStatus', 'No');

          await prefs.remove('orderId');
          await prefs.remove('qrCodeUrl');
          print('Cleared orderId and qrCodeUrl from SharedPreferences');
        } else {
          state = state.copyWith(isCheckingStatus: false);
          print('No payments found for Order ID: $orderId');
        }
      } else {
        state = state.copyWith(isCheckingStatus: false);
        print('Failed to fetch payment status: $orderId');
      }
    } catch (e) {
      state = state.copyWith(isCheckingStatus: false);
      print('Error while fetching payment status: $e');
    }
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(),
);

class ConfirmationButton extends ConsumerStatefulWidget {
  final String label;
  final bool isChecked;
  final double totalAmount;
  final ValueChanged<bool> onConfirmed;

  const ConfirmationButton({
    super.key,
    required this.label,
    required this.isChecked,
    required this.onConfirmed,
    required this.totalAmount,
  });

  @override
  _ConfirmationButtonState createState() => _ConfirmationButtonState();
}

class _ConfirmationButtonState extends ConsumerState<ConfirmationButton> {
  @override
  // void initState() {
  //   super.initState();
  //   ref.read(paymentProvider.notifier).loadQRCodeDataFromSharedPreferences();
  //   // _startRealtimePaymentStatusCheck();
  // }

  // void _startRealtimePaymentStatusCheck() {
  //   _statusCheckTimer = Timer.periodic(
  //     const Duration(seconds: 5),
  //     (timer) {
  //       final paymentState = ref.read(paymentProvider);
  //       if (paymentState.orderId.isNotEmpty && !paymentState.isCaptured) {
  //         ref
  //             .read(paymentProvider.notifier)
  //             .checkPaymentStatus(paymentState.orderId);
  //       } else {
  //         timer.cancel();
  //       }
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final paymentNotifier = ref.read(paymentProvider.notifier);
    ref.watch(orderProvider);

    ref.watch(orderProvider);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              color: widget.isChecked ? const Color(0xFF273847) : Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      '${widget.label} ₹${widget.totalAmount.toStringAsFixed(0)}/-',
                      style: GoogleFonts.poppins(
                        color: widget.isChecked
                            ? Colors.white
                            : const Color(0xFF273847),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Checkbox(
                  value: widget.isChecked || paymentState.isCaptured,
                  onChanged: (bool? value) {
                    widget.onConfirmed(value ?? false);
                  },
                  activeColor: Colors.white,
                  checkColor: const Color(0xFF273847),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage(
                            'assets/c46d810b-ff29-4958-8405-d9599845e9e2-smallBlur_QRCode.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: paymentState.isCreatingQRCode
                            ? ColorFilter.mode(
                                Colors.black.withOpacity(0.10),
                                BlendMode.darken,
                              )
                            : null,
                      ),
                      border: Border.all(color: Colors.grey.shade100, width: 2),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: paymentState.isCaptured
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 150.0,
                            )
                          : paymentState.qrCodeUrl.isNotEmpty
                              ? Image.network(
                                  paymentState.qrCodeUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: const Color(0xFF273847),
                                        strokeWidth: 5,
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return ElevatedButton(
                                      onPressed: () {
                                        ref
                                            .read(paymentProvider.notifier)
                                            .loadQRCodeDataFromSharedPreferences();
                                      },
                                      child: Text(
                                        'Retry',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF273847),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    backgroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    splashFactory: NoSplash.splashFactory,
                                  ),
                                  onPressed: () async {
                                    await ref
                                        .read(paymentProvider.notifier)
                                        .createQRCode(widget.totalAmount);
                                  },
                                  child: paymentState.isCreatingQRCode
                                      ? LoadingAnimationWidget.inkDrop(
                                          color: Colors.black,
                                          size: 30,
                                        )
                                      : Text(
                                          'Show QR Code',
                                          style: GoogleFonts.poppins(
                                              color: Colors.black),
                                        ),
                                ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
          paymentState.isCheckingStatus
              ? LoadingAnimationWidget.inkDrop(
                  color: const Color(0xFF273847), size: 30)
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: TextButton(
                    onPressed: () {
                      if (paymentState.orderId.isNotEmpty) {
                        paymentNotifier
                            .checkPaymentStatus(paymentState.orderId);
                      } else {
                        print("Order ID not yet initialized.");
                      }
                    },
                    child: Text('Check Payment Status',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF273847),
                        )),
                  ),
                ),
        ],
      ),
    );
  }
}
