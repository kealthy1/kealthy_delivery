import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  // Define the API URL directly in the class
  static const String _notificationApiUrl =
      'https://api-jfnhkjk4nq-uc.a.run.app/sendNotification';

  NotificationService._privateConstructor();

  static final NotificationService instance =
      NotificationService._privateConstructor();

  Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_notificationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully: ${response.body}');
      } else {
        print('Error sending notification: ${response.body}');
        throw Exception('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Exception sending notification: $e');
    }
  }
}
