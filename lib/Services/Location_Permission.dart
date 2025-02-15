import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class LocationAccessWidget extends StatelessWidget {
  final Function onClose;

  const LocationAccessWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/location.png',
            height: MediaQuery.of(context).size.height * 0.15,
            width: MediaQuery.of(context).size.width * 0.9,
          ),
          Text(
            'Location Access',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Turning off location will lead to account block and penalties. Please keep location services enabled to continue using The App.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  }
                },
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool serviceEnabled =
                      await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    await Geolocator.openLocationSettings();
                  } else {
                    onClose();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'ENABLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LocationServiceChecker {
  final BuildContext context;
  Timer? _timer;
  bool _isAlertShown = false;

  LocationServiceChecker(this.context);

  void startChecking() {
    print("Starting location service check...");
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      bool isEnabled = await Geolocator.isLocationServiceEnabled();
      print("Location enabled: $isEnabled");
      if (!isEnabled && !_isAlertShown) {
        _showLocationAccessWidget();
      } else if (isEnabled && _isAlertShown) {
        Navigator.of(context).pop();
        _isAlertShown = false;
      }
    });
  }

  void stopChecking() {
    print("Stopping location service check...");
    _timer?.cancel();
  }

  void _showLocationAccessWidget() {
    if (!context.mounted) {
      print("Context is not mounted!");
      return;
    }

    if (_isAlertShown) {
      print("Alert already shown.");
      return;
    }

    print("Showing location access widget...");
    _isAlertShown = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return LocationAccessWidget(
          onClose: () {
            Navigator.of(context).pop();
            _isAlertShown = false;
            print("Location access widget closed.");
          },
        );
      },
    );
  }
}
