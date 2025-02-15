import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';

class NotificationService with WidgetsBindingObserver {
  
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAppInForeground = true;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this); 

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final imageUrl = message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl;

      NotificationService.instance.showNotification(
        title: message.notification?.title ?? "Foreground Notification",
        body: message.notification?.body ?? "No details available",
        imageUrl: imageUrl,
        playSoundContinuously: true,
      );
    });

    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    await setupFlutterNotifications();
  }
  

  Future<void> setupFlutterNotifications() async {
    if (_isInitialized) return;

    const channel = AndroidNotificationChannel(
      'custom_sound_channel',
      'Custom Sound Notifications',
      description: 'This channel uses a custom notification sound.',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(settings);
    _isInitialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? imageUrl,
    bool playSoundContinuously = false,
  }) async {
    BigPictureStyleInformation? bigPictureStyle;

    if (imageUrl != null) {
      try {
        final imageBytes = await _downloadImage(imageUrl);
        final bigPicture = ByteArrayAndroidBitmap(imageBytes);

        bigPictureStyle = BigPictureStyleInformation(
          bigPicture,
          contentTitle: title,
          summaryText: body,
        );
      } catch (e) {
        print('Failed to load notification image: $e');
      }
    }

    Int64List vibrationPattern = Int64List.fromList([0, 500, 1000, 500]);

    await _localNotifications.show(
      title.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'custom_sound_channel',
          'Custom Sound Notifications',
          channelDescription: 'This channel uses a custom notification sound.',
          importance: Importance.high,
          priority: Priority.high,
          vibrationPattern: vibrationPattern,
          styleInformation: bigPictureStyle,
          icon: 'drawable/ic_notification',
          enableVibration: true,
          
          sound: const RawResourceAndroidNotificationSound('notification_sound'),
        ),
      ),
    );

    if (playSoundContinuously) {
      _playContinuousSound();
    }
  }

  Future<void> _playContinuousSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('notification_sound.mp3'));

      if (_isAppInForeground) {
        await Future.delayed(const Duration(seconds: 5));
        await _audioPlayer.stop();
      }
    } catch (e) {
      print('Error playing continuous sound: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      _audioPlayer.stop();
    } else if (state == AppLifecycleState.paused) {
      _isAppInForeground = false;
    }
  }

  Future<Uint8List> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download image from $url');
    }
  }
}
