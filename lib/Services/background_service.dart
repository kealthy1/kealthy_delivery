import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';

import 'fcm.dart';
import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  print('Initializing background service...');
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      foregroundServiceNotificationId: 888,
      initialNotificationContent: 'On the Way',
      initialNotificationTitle: 'Kealthy Delivery Service',
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: (_) async => false,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  final db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
  );

  Timer.periodic(const Duration(minutes: 2), (_) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderId = prefs.getString('orderId');

      print('Background service running for orderId: $orderId');
      if (orderId == null || orderId.isEmpty) return;

      // ✅ Check order exists
      final orderSnap = await db.ref('orders/$orderId').get();
      if (!orderSnap.exists) {
        print('Order not found in /orders. Skipping DALocation update.');

        // Optional: stop trying forever for a deleted order
        await prefs.remove('orderId');

        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locRef = db.ref('orders/$orderId/DALocation');

      print('Updating location → lat: ${pos.latitude}, lng: ${pos.longitude}');

      // Use update (safer) or set (both ok)
      await locRef.update({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('DALocation updated successfully for orderId: $orderId');
    } catch (e) {
      print('DA location update error: $e');
    }
  });
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp();

    return Future.value(true);
  });
}

Future<void> requestPermissions() async {
  await Permission.notification.request();
  await Permission.locationAlways.request();
}

class PermissionService {
  Future<void> requestPermissions() async {
    final notificationStatus = await Permission.notification.request();

    if (notificationStatus.isGranted) {
      final locationStatus = await Permission.location.request();

      final backgroundLocationStatus =
          await Permission.locationAlways.request();

      if (locationStatus.isGranted && backgroundLocationStatus.isGranted) {
        print("All location permissions granted.");
      } else {
        if (!locationStatus.isGranted) {
          print("Foreground location permission not granted.");
        }
        if (!backgroundLocationStatus.isGranted) {
          print("Background location permission not granted.");
        }
      }
    } else {
      print("Notification permission not granted.");
    }
  }

  void listenForOrderAssignments() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? assignedId = prefs.getString('ID');
    final DatabaseReference orderRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
    ).ref('orders');

    final Set<String> shownOrderIds = {};

    orderRef.onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        for (var entry in data.entries) {
          final orderId = entry.key;
          final orderData = entry.value;
          final assignedTo = orderData['assignedto'];

          if (assignedTo == assignedId) {
            if (!shownOrderIds.contains(orderId)) {
              await NotificationService.instance.showNotification(
                title: "New Order",
                body: "Order has been assigned to you.",
                playSoundContinuously: true,
              );

              shownOrderIds.add(orderId);
            }
          }
        }
      }
    });
  }
}
