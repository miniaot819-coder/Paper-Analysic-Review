import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/research_notification.dart';

abstract class MessagingGateway {
  Stream<RemoteMessage> get foregroundMessages;
  Stream<RemoteMessage> get openedMessages;
  Stream<String> get tokenRefreshes;

  Future<void> initialize();
  Future<NotificationSettings> getNotificationSettings();
  Future<NotificationSettings> requestPermission();
  Future<String?> getToken();
  Future<RemoteMessage?> getInitialMessage();
}

class MessagingService implements MessagingGateway {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;
  @override
  Stream<RemoteMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp;
  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<void> initialize() async {
    await _messaging.setAutoInitEnabled(true);
  }

  @override
  Future<NotificationSettings> getNotificationSettings() {
    return _messaging.getNotificationSettings();
  }

  @override
  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();
}

ResearchNotification researchNotificationFromRemoteMessage(
  RemoteMessage message, {
  required ResearchNotificationSource source,
  bool isRead = false,
  DateTime? now,
}) {
  final title = _firstNonEmpty([
    message.notification?.title,
    message.data['title']?.toString(),
  ], fallback: 'Research update');
  final body = _firstNonEmpty([
    message.notification?.body,
    message.data['body']?.toString(),
  ], fallback: 'A new research trend update is available.');
  final receivedAt = message.sentTime?.toLocal() ?? now ?? DateTime.now();
  final id = _firstNonEmpty(
    [message.messageId],
    fallback:
        '${receivedAt.millisecondsSinceEpoch}_${title.hashCode}_${body.hashCode}',
  );

  return ResearchNotification(
    id: id,
    title: title,
    body: body,
    receivedAt: receivedAt,
    source: source,
    isRead: isRead,
    type: _nullableText(message.data['type']),
    topic: _nullableText(message.data['topic']),
  );
}

String _firstNonEmpty(List<String?> values, {required String fallback}) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return fallback;
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
