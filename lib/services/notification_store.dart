import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/research_notification.dart';

abstract class NotificationStore {
  static const defaultMaximumItems = 50;

  Future<List<ResearchNotification>> load();

  Future<void> save(List<ResearchNotification> notifications);

  Future<void> upsert(ResearchNotification notification);
}

class SharedPreferencesNotificationStore implements NotificationStore {
  SharedPreferencesNotificationStore({
    required String userId,
    SharedPreferencesAsync? preferences,
    this.maximumItems = NotificationStore.defaultMaximumItems,
  }) : userId = _requireUserId(userId),
       _preferences = preferences ?? SharedPreferencesAsync() {
    if (maximumItems <= 0) {
      throw ArgumentError.value(
        maximumItems,
        'maximumItems',
        'Must be greater than zero.',
      );
    }
  }

  static const storageKeyPrefix = 'research_notifications_v2';

  final SharedPreferencesAsync _preferences;
  final String userId;
  final int maximumItems;

  /// Keeps notification history isolated for each signed-in Firebase user.
  /// The previous unscoped v1 key is intentionally not migrated because its
  /// owner cannot be determined safely.
  String get storageKey => storageKeyForUser(userId);

  static String storageKeyForUser(String userId) {
    final normalizedUserId = _requireUserId(userId);
    final encodedUserId = base64Url
        .encode(utf8.encode(normalizedUserId))
        .replaceAll('=', '');
    return '${storageKeyPrefix}_$encodedUserId';
  }

  @override
  Future<List<ResearchNotification>> load() async {
    final encoded = await _preferences.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return const [];

    try {
      final values = jsonDecode(encoded) as List<dynamic>;
      final notifications = values
          .map(
            (value) => ResearchNotification.fromJson(
              Map<String, Object?>.from(value as Map),
            ),
          )
          .toList();
      notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return notifications.take(maximumItems).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(List<ResearchNotification> notifications) async {
    final limited = notifications.take(maximumItems);
    await _preferences.setString(
      storageKey,
      jsonEncode(limited.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> upsert(ResearchNotification notification) async {
    final current = await load();
    final updated = <ResearchNotification>[
      notification,
      ...current.where((item) => item.id != notification.id),
    ];
    await save(updated);
  }
}

String _requireUserId(String userId) {
  final normalized = userId.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
  }
  return normalized;
}
