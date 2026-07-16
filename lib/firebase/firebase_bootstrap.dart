import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'analytics_tracking_service.dart';
import 'messaging_service.dart';
import 'remote_config_service.dart';
import '../models/research_notification.dart';
import '../services/notification_store.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null || userId.trim().isEmpty) return;
  final notification = researchNotificationFromRemoteMessage(
    message,
    source: ResearchNotificationSource.background,
  );
  await SharedPreferencesNotificationStore(userId: userId).upsert(notification);
}

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool isEnabled = false;
  static Object? initializationError;

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();

      await RemoteConfigService.instance.initialize();
      await AnalyticsTrackingService.instance.logAppBootstrap();
      _initializeMessagingLater();

      isEnabled = true;
      initializationError = null;
      return true;
    } catch (error) {
      isEnabled = false;
      initializationError = error;
      return false;
    }
  }

  static void _initializeMessagingLater() {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      unawaited(MessagingService.instance.initialize().catchError((_) {}));
    } catch (_) {
      // FCM is configured in a later phase; it should not block core Firebase.
    }
  }
}
