import 'package:firebase_messaging/firebase_messaging.dart';

/// Push notifications are not initialized on web in this build (FCM web deferred).
class NotificationService {
  static Future<void> initialize() async {}

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
}
