import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class LocationUpdater {
  Stream<Position>? _positionStream;

  Future<void> startLocationUpdates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('ID');

    if (id == null) {
      print("No ID found in SharedPreferences.");
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print("Location permissions are denied.");
        return;
      }
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, 
      ),
    );

    _positionStream?.listen((Position position) async {
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      print("Updating location: $currentLocation");

      try {
        await FirebaseFirestore.instance
            .collection('DeliveryUsers')
            .doc(id)
            .set(
          {
            'currentLocation':
                GeoPoint(currentLocation.latitude, currentLocation.longitude),
          },
          SetOptions(merge: true),
        );

        print("Location successfully updated in Firestore.");
      } catch (e) {
        print("Error updating location: $e");
      }
    });
  }

  Future<void> stopLocationUpdates() async {
    if (_positionStream != null) {
      await _positionStream?.drain();
      _positionStream = null;
      print("Location updates stopped.");
    }
  }
}
