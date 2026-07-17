import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/research_notification.dart';

abstract class NotificationStore {
  static const defaultMaximumItems = 50;

  Future<List<ResearchNotification>> load();

  Future<void> save(List<ResearchNotification> notifications);

  Future<void> upsert(ResearchNotification notification);

  Future<void> clear() => save(const []);
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
  static const _itemStorageKeyPrefix = 'research_notifications_v3';

  final SharedPreferencesAsync _preferences;
  final String userId;
  final int maximumItems;

  /// Keeps notification history isolated for each signed-in Firebase user.
  /// The previous unscoped v1 key is intentionally not migrated because its
  /// owner cannot be determined safely.
  String get storageKey => storageKeyForUser(userId);
  String get _storageNamespace => _storageNamespaceForUser(userId);
  String get _itemKeyPrefix => '$_storageNamespace.item.';
  String get _readKeyPrefix => '$_storageNamespace.read.';

  static String storageKeyForUser(String userId) {
    return '${storageKeyPrefix}_${_encodedUserId(userId)}';
  }

  static String _storageNamespaceForUser(String userId) {
    return '${_itemStorageKeyPrefix}_${_encodedUserId(userId)}';
  }

  static String _encodedUserId(String userId) {
    final normalizedUserId = _requireUserId(userId);
    return base64Url.encode(utf8.encode(normalizedUserId)).replaceAll('=', '');
  }

  @override
  Future<List<ResearchNotification>> load() async {
    await _migrateLegacyStorage();
    final notifications = await _loadAll();
    return notifications.take(maximumItems).toList(growable: false);
  }

  @override
  Future<void> save(List<ResearchNotification> notifications) async {
    if (notifications.isEmpty) {
      await clear();
      return;
    }

    // Each notification has an independent key. Updating the main-isolate
    // snapshot therefore cannot overwrite a message concurrently inserted by
    // Firebase Messaging's background isolate.
    for (final notification in notifications.take(maximumItems)) {
      await _writeNotification(notification);
    }
    await _prune();
  }

  @override
  Future<void> upsert(ResearchNotification notification) async {
    await _writeNotification(notification);
    await _prune();
  }

  @override
  Future<void> clear() async {
    final values = await _preferences.getAll();
    final keys = values.keys
        .where(
          (key) => key == storageKey || key.startsWith('$_storageNamespace.'),
        )
        .toSet();
    if (keys.isNotEmpty) await _preferences.clear(allowList: keys);
  }

  Future<List<ResearchNotification>> _loadAll() async {
    final values = await _preferences.getAll();
    final notificationsById = <String, ResearchNotification>{};

    for (final entry in values.entries) {
      if (!entry.key.startsWith(_itemKeyPrefix) || entry.value is! String) {
        continue;
      }

      try {
        final decoded = jsonDecode(entry.value! as String);
        final notification = ResearchNotification.fromJson(
          Map<String, Object?>.from(decoded as Map),
        );
        final isRead =
            notification.isRead || values[_readKey(notification.id)] == true;
        final resolved = isRead && !notification.isRead
            ? notification.copyWith(isRead: true)
            : notification;
        final existing = notificationsById[resolved.id];
        if (existing == null ||
            resolved.receivedAt.isAfter(existing.receivedAt)) {
          notificationsById[resolved.id] = resolved;
        }
      } catch (_) {
        // Ignore one corrupt entry without discarding the user's full history.
      }
    }

    final notifications = notificationsById.values.toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return notifications;
  }

  Future<void> _writeNotification(ResearchNotification notification) async {
    // Read state is monotonic. Writing the marker before the content prevents
    // a late background delivery of the same FCM message from making an
    // already-opened notification unread again.
    if (notification.isRead) {
      await _preferences.setBool(_readKey(notification.id), true);
    }
    await _preferences.setString(
      _itemKey(notification.id),
      jsonEncode(notification.toJson()),
    );
  }

  Future<void> _prune() async {
    final notifications = await _loadAll();
    if (notifications.length <= maximumItems) return;

    for (final notification in notifications.skip(maximumItems)) {
      await _preferences.remove(_itemKey(notification.id));
      await _preferences.remove(_readKey(notification.id));
    }
  }

  Future<void> _migrateLegacyStorage() async {
    final encoded = await _preferences.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return;

    late final List<dynamic> values;
    try {
      values = jsonDecode(encoded) as List<dynamic>;
    } catch (_) {
      // A corrupt legacy blob should not block the new per-item store.
      await _preferences.remove(storageKey);
      return;
    }

    for (final value in values.take(maximumItems)) {
      ResearchNotification notification;
      try {
        notification = ResearchNotification.fromJson(
          Map<String, Object?>.from(value as Map),
        );
      } catch (_) {
        // Continue migrating the remaining valid legacy entries.
        continue;
      }

      // Persistence errors deliberately escape so the v2 blob remains and a
      // later app start can retry the idempotent migration safely.
      if (!await _preferences.containsKey(_itemKey(notification.id))) {
        await _writeNotification(notification);
      }
    }

    await _preferences.remove(storageKey);
  }

  String _itemKey(String notificationId) {
    return '$_itemKeyPrefix${_encodedNotificationId(notificationId)}';
  }

  String _readKey(String notificationId) {
    return '$_readKeyPrefix${_encodedNotificationId(notificationId)}';
  }

  String _encodedNotificationId(String notificationId) {
    return base64Url.encode(utf8.encode(notificationId)).replaceAll('=', '');
  }
}

String _requireUserId(String userId) {
  final normalized = userId.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
  }
  return normalized;
}
