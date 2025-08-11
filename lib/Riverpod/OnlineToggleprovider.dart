import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_bubble/dash_bubble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Request_Overlay.dart';

class LocationState {
  final LatLng? location;
  final bool isOnline;

  LocationState({required this.location, required this.isOnline});
}

class LocationNotifier extends StateNotifier<LocationState> {
  final RequestOverlay requestOverlay;

  LocationNotifier()
    : requestOverlay = RequestOverlay(),
      super(LocationState(location: null, isOnline: false)) {
    _initializeLocationAndStatus();
  }

  Future<void> _initializeLocationAndStatus() async {
    // await _determinePosition();
    await _fetchInitialOnlineStatus();
  }

  // Future<void> _determinePosition() async {
  //   LocationPermission permission = await Geolocator.checkPermission();

  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //   }

  //   if (permission == LocationPermission.denied) {
  //     return;
  //   }

  //   Position position = await Geolocator.getCurrentPosition();
  //   state = LocationState(
  //     location: LatLng(position.latitude, position.longitude),
  //     isOnline: state.isOnline,
  //   );
  // }

  Future<void> _fetchInitialOnlineStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('ID');

    if (id != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('DeliveryUsers')
              .doc(id)
              .get();

      if (snapshot.exists) {
        bool isOnline = snapshot['Status'] == 'Online';
        state = LocationState(location: state.location, isOnline: isOnline);
        if (isOnline) {
          _startBubble();
        }
      }
    }
  }

  Future<void> toggleOnlineStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('ID');

    LatLng allowedLocation = const LatLng(
      10.010321689460884,
      76.38432031349255,
    );
    if (!state.isOnline) {
      double distanceInMeters = Geolocator.distanceBetween(
        state.location!.latitude,
        state.location!.longitude,
        allowedLocation.latitude,
        allowedLocation.longitude,
      );

      if (distanceInMeters <= 100) {
        await _setOnlineStatus(id, true);
      } else {
        throw ("You are out of the allowed range to toggle the status.");
      }
    } else {
      await _setOnlineStatus(id, false);
    }
  }

  Future<void> _setOnlineStatus(String? id, bool newStatus) async {
    await FirebaseFirestore.instance.collection('DeliveryUsers').doc(id).update(
      {'Status': newStatus ? 'Online' : 'Offline'},
    );

    state = LocationState(location: state.location, isOnline: newStatus);

    if (newStatus) {
      _startBubble();
    } else {
      await requestOverlay.stopBubble();
    }
  }

  void _startBubble() {
    requestOverlay.startBubble(
      BubbleOptions(
        bubbleIcon: "bubble",
        bubbleSize: 40,
        enableClose: false,
        distanceToClose: 90,
        enableAnimateToEdge: true,
        enableBottomShadow: true,
        keepAliveWhenAppExit: false,
      ),
      onTap: () {
        requestOverlay.logMessage(message: "Bubble Tapped");
      },
    );
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier();
  },
);
