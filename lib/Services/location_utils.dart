import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

Future<LocationPermission> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission;
}

void checkPermissionAndNotify(BuildContext context) async {
  LocationPermission permission = await requestLocationPermission();

  if (permission == LocationPermission.denied) {
    _showLocationPermissionDeniedAlert(context);
  } else if (permission == LocationPermission.deniedForever) {
    _showLocationPermissionDeniedAlert(context);
  }
}
void _showLocationPermissionDeniedAlert(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Location Permission Denied'),
      content: const Text('Please enable location permissions to use this feature.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<bool> isWithinDistance({
  required double targetLat,
  required double targetLong,
  double thresholdDistanceInMeters = 100,
}) async {
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  double currentLat = position.latitude;
  double currentLong = position.longitude;

  double distanceInMeters = Geolocator.distanceBetween(currentLat, currentLong, targetLat, targetLong);
  return distanceInMeters <= thresholdDistanceInMeters;
}
