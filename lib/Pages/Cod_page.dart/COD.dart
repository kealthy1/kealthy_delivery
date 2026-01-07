import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gif_view/gif_view.dart';
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
  final String qrId;

  PaymentState({
    required this.isCaptured,
    this.isLoading = false,
    this.isCreatingQRCode = false,
    this.isCheckingStatus = false,
    this.orderId = '',
    this.qrCodeUrl = '',
    this.qrId = '',
  });

  PaymentState copyWith({
    bool? isCaptured,
    bool? isLoading,
    bool? isCreatingQRCode,
    bool? isCheckingStatus,
    String? orderId,
    String? qrCodeUrl,
    String? qrId,
  }) {
    return PaymentState(
      isCaptured: isCaptured ?? this.isCaptured,
      isLoading: isLoading ?? this.isLoading,
      isCreatingQRCode: isCreatingQRCode ?? this.isCreatingQRCode,
      isCheckingStatus: isCheckingStatus ?? this.isCheckingStatus,
      orderId: orderId ?? this.orderId,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      qrId: qrId ?? this.qrId,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(PaymentState(isCaptured: false));
  static final int qrValidityDuration = Duration(minutes: 15).inMilliseconds;
  Future<void> loadQRCodeDataFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qrTimestamp = prefs.getInt('qrTimestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final qrValidityDuration = Duration(minutes: 15).inMilliseconds;

      if (currentTime - qrTimestamp > PaymentNotifier.qrValidityDuration) {
        await prefs.remove('orderId');
        await prefs.remove('qrCodeUrl');
        await prefs.remove('qrId');
        await prefs.remove('qrTimestamp');
        state = state.copyWith(
          orderId: '',
          qrCodeUrl: '',
          qrId: '',
          isCaptured: false,
        );
        print('Cleared expired QR code data from SharedPreferences');
      } else {
        final orderId = prefs.getString('orderId') ?? '';
        final qrCodeUrl = prefs.getString('qrCodeUrl') ?? '';
        final qrId = prefs.getString('qrId') ?? '';
        state = state.copyWith(
          orderId: orderId,
          qrCodeUrl: qrCodeUrl,
          qrId: qrId,
        );
        print('Loaded QR code data from SharedPreferences');
      }
    } catch (e) {
      print('Error loading data from shared preferences: $e');
    }
  }

  Future<void> createQRCode(double amount) async {
    try {
      state = state.copyWith(
        orderId: '',
        qrCodeUrl: '',
        qrId: '',
        isCaptured: false,
        isCreatingQRCode: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('orderId');
      await prefs.remove('qrCodeUrl');
      await prefs.remove('qrId');
      await prefs.remove('qrTimestamp');

      final response = await http.post(
        Uri.parse('https://razor-pay-kappa-two.vercel.app/api/qr/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);

        if (decodedResponse['success'] == true &&
            decodedResponse['orderId'] != null &&
            decodedResponse['image_url'] != null &&
            decodedResponse['id'] != null) {
          final orderId = decodedResponse['orderId'];
          final qrCodeUrl = decodedResponse['image_url'];
          final qrId = decodedResponse['id'];

          await _saveToSharedPreferences(orderId, qrCodeUrl, qrId);
          state = state.copyWith(
            orderId: orderId,
            qrCodeUrl: qrCodeUrl,
            qrId: qrId,
            isCreatingQRCode: false,
            isCaptured: false,
          );
          print('QR Code created successfully with Order ID: $orderId');
        } else {
          state = state.copyWith(isCreatingQRCode: false);
          print(
            'Error: orderId, image_url, or id is missing in the response data',
          );
        }
      } else {
        state = state.copyWith(isCreatingQRCode: false);
        print(
          'Failed to create QR code. Status code: ${response.statusCode}, Response: ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(isCreatingQRCode: false);
      print('Error while creating QR code: $e');
    }
  }

  Future<void> _saveToSharedPreferences(
    String orderId,
    String qrCodeUrl,
    String qrId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('orderId', orderId);
      await prefs.setString('qrCodeUrl', qrCodeUrl);
      await prefs.setString('qrId', qrId);
      await prefs.setInt('qrTimestamp', DateTime.now().millisecondsSinceEpoch);
      print(
        'Successfully saved orderId, qrCodeUrl, qrId, and timestamp to shared preferences',
      );
    } catch (e) {
      print(orderId);
      print(qrCodeUrl);
      print(qrId);
      print('Error saving data to shared preferences: $e');
    }
  }

  Future<void> checkPaymentStatus(String qrId) async {
    try {
      state = state.copyWith(isCheckingStatus: true);
      final response = await http.post(
        Uri.parse('https://razor-pay-kappa-two.vercel.app/api/qr/check'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': qrId}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null &&
            data['success'] == true &&
            data['paid'] == true &&
            data['status'] == 'captured') {
          state = state.copyWith(isCaptured: true, isCheckingStatus: false);
          print('Payment captured for QR ID: $qrId');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('paymentStatus', 'Yes');
          await prefs.remove('orderId');
          await prefs.remove('qrCodeUrl');
          await prefs.remove('qrId');
          await prefs.remove('qrTimestamp');
          print(
            'Cleared orderId, qrCodeUrl, qrId, and timestamp from SharedPreferences',
          );
        } else {
          state = state.copyWith(isCheckingStatus: false);
          print('Payment not yet captured for QR ID: $qrId');
        }
      } else {
        state = state.copyWith(isCheckingStatus: false);
        print(
          'Failed to fetch payment status: $qrId, Status code: ${response.statusCode}, Response: ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(isCheckingStatus: false);
      print('Error while fetching payment status: $e');
    }
  }

  Future<void> clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('orderId');
      await prefs.remove('qrCodeUrl');
      await prefs.remove('qrId');
      await prefs.remove('qrTimestamp');
      await prefs.remove('paymentStatus');
      state = state.copyWith(
        orderId: '',
        qrCodeUrl: '',
        qrId: '',
        isCaptured: false,
        isCreatingQRCode: false,
        isCheckingStatus: false,
      );
      print('Cleared SharedPreferences and reset PaymentState');
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
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
  Timer? _statusCheckTimer;
  int _failedStatusChecks = 0;
  static const int _maxFailedChecks = 5;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(paymentProvider.notifier).clearSharedPreferences();
      ref.read(paymentProvider.notifier).loadQRCodeDataFromSharedPreferences();
      _startRealtimePaymentStatusCheck();
    });
  }

  void _startRealtimePaymentStatusCheck() {
    _statusCheckTimer?.cancel();
    _failedStatusChecks = 0; // Reset failed checks counter
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 4), (
      timer,
    ) async {
      final paymentState = ref.read(paymentProvider);
      final prefs = await SharedPreferences.getInstance();
      final qrTimestamp = prefs.getInt('qrTimestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (paymentState.qrId.isNotEmpty && !paymentState.isCaptured
      // &&
      // currentTime - qrTimestamp <= PaymentNotifier.qrValidityDuration
      ) {
        try {
          await ref
              .read(paymentProvider.notifier)
              .checkPaymentStatus(paymentState.qrId);
          _failedStatusChecks = 0; // Reset on successful check
          if (ref.read(paymentProvider).isCaptured) {
            timer.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text('Payment confirmed successfully!'),
              ),
            );
          }
        } catch (e) {
          _failedStatusChecks++;
          if (_failedStatusChecks >= _maxFailedChecks) {
            timer.cancel();

            await ref.read(paymentProvider.notifier).clearSharedPreferences();
          }
        }
      } else {
        timer.cancel();
        if (currentTime - qrTimestamp > PaymentNotifier.qrValidityDuration) {
          await ref.read(paymentProvider.notifier).clearSharedPreferences();
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('QR code has expired. Please generate a new one.'),
          //   ),
          // );
        }
      }
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    ref.read(paymentProvider.notifier).clearSharedPreferences();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final paymentNotifier = ref.read(paymentProvider.notifier);
    ref.watch(orderProvider);

    // Show error if QR code creation fails
    if (paymentState.qrCodeUrl.isEmpty &&
        !paymentState.isCreatingQRCode &&
        paymentState.orderId.isEmpty &&
        !paymentState.isCaptured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {});
    }

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
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      '${widget.label} ₹${widget.totalAmount.toStringAsFixed(0)}/-',
                      style: GoogleFonts.poppins(
                        color:
                            widget.isChecked
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
                          'assets/c46d810b-ff29-4958-8405-d9599845e9e2-smallBlur_QRCode.jpg',
                        ),
                        fit: BoxFit.cover,
                        colorFilter:
                            paymentState.isCreatingQRCode
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
                      child:
                          paymentState.isCaptured
                              ? Image.asset(
                                'assets/Success.gif',
                                height: 300,
                                width: 300,
                              )
                              : paymentState.qrCodeUrl.isNotEmpty &&
                                  !paymentState.isCreatingQRCode
                              ? Image.network(
                                paymentState.qrCodeUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: const Color(0xFF273847),
                                      strokeWidth: 5,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
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
                                      .clearSharedPreferences();
                                  await ref
                                      .read(paymentProvider.notifier)
                                      .createQRCode(widget.totalAmount);
                                  _startRealtimePaymentStatusCheck();
                                },
                                child:
                                    paymentState.isCreatingQRCode
                                        ? LoadingAnimationWidget.inkDrop(
                                          color: Colors.black,
                                          size: 30,
                                        )
                                        : Text(
                                          'Show QR Code',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                          ),
                                        ),
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
          Container(
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
                if (paymentState.qrId.isNotEmpty) {
                  paymentNotifier.checkPaymentStatus(paymentState.qrId);
                  _startRealtimePaymentStatusCheck(); // Restart timer after manual check
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No QR code available to check.')),
                  );
                }
              },
              child: Text(
                paymentState.isCheckingStatus
                    ? 'Checking Status...'
                    : 'Check Payment Status',
                style: GoogleFonts.poppins(color: const Color(0xFF273847)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
