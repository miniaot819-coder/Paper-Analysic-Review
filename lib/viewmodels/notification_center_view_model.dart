import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase/messaging_service.dart';
import '../models/research_notification.dart';
import '../services/notification_store.dart';

typedef NotificationCallback = void Function(ResearchNotification notification);

class NotificationCenterViewModel extends ChangeNotifier {
  NotificationCenterViewModel({
    required String userId,
    MessagingGateway? messaging,
    NotificationStore? store,
    this.maximumItems = NotificationStore.defaultMaximumItems,
    this.onForegroundNotification,
    this.onNotificationOpened,
  }) : userId = _requireUserId(userId),
       _messaging = messaging ?? MessagingService.instance,
       _store = store ?? SharedPreferencesNotificationStore(userId: userId) {
    if (maximumItems <= 0) {
      throw ArgumentError.value(
        maximumItems,
        'maximumItems',
        'Must be greater than zero.',
      );
    }
  }

  final MessagingGateway _messaging;
  final NotificationStore _store;
  final String userId;
  final int maximumItems;
  final NotificationCallback? onForegroundNotification;
  final NotificationCallback? onNotificationOpened;

  final List<ResearchNotification> _notifications = [];
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;

  AuthorizationStatus _authorizationStatus = AuthorizationStatus.notDetermined;
  String? _token;
  String? _errorMessage;
  bool _isInitializing = false;
  bool _isRequestingPermission = false;
  bool _isDisposed = false;
  bool _didCheckInitialMessage = false;

  List<ResearchNotification> get notifications =>
      List.unmodifiable(_notifications);
  AuthorizationStatus get authorizationStatus => _authorizationStatus;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isInitializing => _isInitializing;
  bool get isRequestingPermission => _isRequestingPermission;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;
  bool get hasPermission =>
      _authorizationStatus == AuthorizationStatus.authorized ||
      _authorizationStatus == AuthorizationStatus.provisional;

  Future<void> initialize() => _runInitialization();

  /// Re-runs setup without adding duplicate stream listeners. This is useful
  /// when permission, network access, or FCM token registration was not ready
  /// during the first attempt.
  Future<void> retryInitialization() => _runInitialization();

  Future<void> _runInitialization() async {
    if (_isInitializing || _isDisposed) return;
    _isInitializing = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      final errors = <String>[];
      _attachListeners(errors);

      try {
        await _messaging.initialize();
      } catch (_) {
        errors.add('Unable to initialize Firebase Cloud Messaging.');
      }
      if (_isDisposed) return;

      try {
        final stored = await _store.load();
        if (_isDisposed) return;
        _notifications
          ..clear()
          ..addAll(stored);
        _sortAndTrimNotifications();
      } catch (_) {
        errors.add('Unable to load the Notification Center.');
      }
      if (_isDisposed) return;

      try {
        final settings = await _messaging.getNotificationSettings();
        if (_isDisposed) return;
        _authorizationStatus = settings.authorizationStatus;
        if (hasPermission) {
          await _refreshToken(errors);
        } else {
          _token = null;
        }
      } catch (_) {
        errors.add('Unable to read notification permission status.');
      }
      if (_isDisposed) return;

      if (!_didCheckInitialMessage) {
        try {
          final initialMessage = await _messaging.getInitialMessage();
          if (_isDisposed) return;
          _didCheckInitialMessage = true;
          if (initialMessage != null) {
            await _handleOpenedMessage(initialMessage);
          }
        } catch (_) {
          errors.add('Unable to check the notification that opened the app.');
        }
      }

      if (!_isDisposed) {
        _errorMessage = errors.isEmpty ? null : errors.join(' ');
      }
    } finally {
      _isInitializing = false;
      _notifyListeners();
    }
  }

  void _attachListeners(List<String> errors) {
    if (_foregroundSubscription == null) {
      try {
        _foregroundSubscription = _messaging.foregroundMessages.listen(
          _handleForegroundMessage,
          onError: (_) => _showReceiveError(),
        );
      } catch (_) {
        errors.add('Unable to listen for foreground notifications.');
      }
    }
    if (_openedSubscription == null) {
      try {
        _openedSubscription = _messaging.openedMessages.listen(
          _handleOpenedMessage,
          onError: (_) => _showReceiveError(),
        );
      } catch (_) {
        errors.add('Unable to listen for opened notifications.');
      }
    }
    if (_tokenSubscription == null) {
      try {
        _tokenSubscription = _messaging.tokenRefreshes.listen((token) {
          _token = token;
          if (_errorMessage == _tokenErrorMessage) _errorMessage = null;
          _notifyListeners();
        }, onError: (_) => _showTokenError());
      } catch (_) {
        errors.add('Unable to listen for FCM token updates.');
      }
    }
  }

  Future<void> _refreshToken(List<String> errors) async {
    try {
      final token = await _messaging.getToken();
      if (_isDisposed) return;
      _token = token;
      if (token == null || token.isEmpty) errors.add(_tokenErrorMessage);
    } catch (_) {
      errors.add(_tokenErrorMessage);
    }
  }

  void _showReceiveError() {
    if (_isDisposed) return;
    _errorMessage =
        'Unable to receive Firebase messages. Check the connection and retry.';
    _notifyListeners();
  }

  void _showTokenError() {
    if (_isDisposed) return;
    _errorMessage = _tokenErrorMessage;
    _notifyListeners();
  }

  Future<void> requestPermission() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      final settings = await _messaging.requestPermission();
      _authorizationStatus = settings.authorizationStatus;
      if (hasPermission) {
        final errors = <String>[];
        await _refreshToken(errors);
        _errorMessage = errors.isEmpty ? null : errors.join(' ');
      } else {
        _token = null;
      }
    } catch (_) {
      _errorMessage =
          'Unable to request notification permission. Please try again.';
    } finally {
      _isRequestingPermission = false;
      _notifyListeners();
    }
  }

  Future<void> reloadStoredNotifications() async {
    try {
      final stored = await _store.load();
      if (_isDisposed) return;
      _notifications
        ..clear()
        ..addAll(stored);
      _sortAndTrimNotifications();
      _notifyListeners();
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = 'Unable to load the Notification Center.';
      _notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _notifyListeners();
    await _persistCurrent();
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    _notifyListeners();
    await _persistCurrent();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    _notifyListeners();
    await _persistCurrent();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = researchNotificationFromRemoteMessage(
      message,
      source: ResearchNotificationSource.foreground,
    );
    await _upsert(notification);
    if (!_isDisposed) onForegroundNotification?.call(notification);
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final notification = researchNotificationFromRemoteMessage(
      message,
      source: ResearchNotificationSource.opened,
      isRead: true,
    );
    await _upsert(notification);
    if (!_isDisposed) onNotificationOpened?.call(notification);
  }

  Future<void> _upsert(ResearchNotification notification) async {
    _notifications.removeWhere((item) => item.id == notification.id);
    _notifications.insert(0, notification);
    _sortAndTrimNotifications();
    _notifyListeners();
    try {
      await _store.upsert(notification);
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = 'Unable to save the received notification.';
      _notifyListeners();
    }
  }

  void _sortAndTrimNotifications() {
    _notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    if (_notifications.length > maximumItems) {
      _notifications.removeRange(maximumItems, _notifications.length);
    }
  }

  Future<void> _persistCurrent() async {
    try {
      await _store.save(_notifications);
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = 'Unable to save Notification Center changes.';
      _notifyListeners();
    }
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedSubscription?.cancel());
    unawaited(_tokenSubscription?.cancel());
    _foregroundSubscription = null;
    _openedSubscription = null;
    _tokenSubscription = null;
    super.dispose();
  }
}

const _tokenErrorMessage =
    'The FCM registration token is not ready. Messages can still be received; '
    'check the connection and retry.';

String _requireUserId(String userId) {
  final normalized = userId.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
  }
  return normalized;
}
