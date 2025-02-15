import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'Location_Permission.dart';

class LocationState {
  final LatLng? location;
  final bool isLocationEnabled;

  LocationState.LocationStates(
      {required this.location, required this.isLocationEnabled});
}

class LocationService extends StateNotifier<LocationState> {
  LocationService()
      : super(LocationState.LocationStates(
            location: null, isLocationEnabled: true));

  Future<void> checkLocationAndShowAlert(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showExitDialog(context,
          "Location services are disabled. Please enable them to continue.");
      state = LocationState.LocationStates(
          location: null, isLocationEnabled: false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showExitDialog(
            context, "Location permission denied. The app will now exit.");
        state = LocationState.LocationStates(
            location: null, isLocationEnabled: false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showExitDialog(context,
          "Location permissions are permanently denied. Enable them in settings. The app will now exit.");
      state = LocationState.LocationStates(
          location: null, isLocationEnabled: false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    state = LocationState.LocationStates(
        location: LatLng(position.latitude, position.longitude),
        isLocationEnabled: true);
  }

  void _showExitDialog(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return LocationAccessWidget(
          onClose: () {
            SystemNavigator.pop;

            print("Location access widget closed."); // Debug
          },
        );
      },
    );
  }
}

/// ✅ Riverpod Provider for `LocationService`
final locationServiceProvider =
    StateNotifierProvider<LocationService, LocationState>((ref) {
  return LocationService();
});
