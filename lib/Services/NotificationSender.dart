import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationSender {
  final String apiUrl;

  NotificationSender({required this.apiUrl});

  /// Sends a notification using the provided API.
  ///
  /// [fcmToken] is the recipient's FCM token.
  /// [title] is the notification title.
  /// [body] is the notification body.
  /// [data] is an optional map for additional payload data.
  Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (fcmToken.isEmpty || title.isEmpty || body.isEmpty) {
      throw Exception("FCM token, title, and body cannot be empty.");
    }

    final notificationPayload = {
      "token": fcmToken,
      "title": title,
      "body": body,
      "data": data ?? {},
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(notificationPayload),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully: ${response.body}");
      } else {
        print("Error sending notification: ${response.body}");
        throw Exception("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("Exception sending notification: $e");
      rethrow;
    }
  }
}
