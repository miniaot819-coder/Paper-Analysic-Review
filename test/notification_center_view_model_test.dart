import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/firebase/messaging_service.dart';
import 'package:journal_trend_analysis/models/research_notification.dart';
import 'package:journal_trend_analysis/services/notification_store.dart';
import 'package:journal_trend_analysis/viewmodels/notification_center_view_model.dart';

void main() {
  test('notification storage keys are isolated by Firebase user ID', () {
    final firstUserKey = SharedPreferencesNotificationStore.storageKeyForUser(
      'firebase-a',
    );
    final secondUserKey = SharedPreferencesNotificationStore.storageKeyForUser(
      'firebase-b',
    );

    expect(firstUserKey, startsWith('research_notifications_v2_'));
    expect(secondUserKey, isNot(firstUserKey));
    expect(
      SharedPreferencesNotificationStore.storageKeyForUser(' firebase-a '),
      firstUserKey,
    );
    expect(
      () => SharedPreferencesNotificationStore.storageKeyForUser('   '),
      throwsArgumentError,
    );
  });

  test('maps notification and research data from an FCM message', () {
    final notification = researchNotificationFromRemoteMessage(
      RemoteMessage(
        messageId: 'message-1',
        sentTime: DateTime.utc(2026, 7, 15, 12),
        notification: const RemoteNotification(
          title: 'AI trend alert',
          body: 'Transformer publications increased this year.',
        ),
        data: const {'type': 'research_trend', 'topic': 'Transformers'},
      ),
      source: ResearchNotificationSource.foreground,
    );

    expect(notification.id, 'message-1');
    expect(notification.title, 'AI trend alert');
    expect(notification.body, contains('Transformer publications'));
    expect(notification.type, 'research_trend');
    expect(notification.topic, 'Transformers');
    expect(notification.source, ResearchNotificationSource.foreground);
    expect(notification.isRead, isFalse);
  });

  test('uses safe fallbacks for a data-only message', () {
    final notification = researchNotificationFromRemoteMessage(
      const RemoteMessage(messageId: 'data-only'),
      source: ResearchNotificationSource.background,
      now: DateTime(2026, 7, 15),
    );

    expect(notification.title, 'Research update');
    expect(notification.body, 'A new research trend update is available.');
  });

  test('initialize loads stored notifications and authorized token', () async {
    final gateway = FakeMessagingGateway(
      currentStatus: AuthorizationStatus.authorized,
      currentToken: 'test-token',
    );
    final store = MemoryNotificationStore([
      _notification('stored', isRead: false),
    ]);
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: store,
    );

    await viewModel.initialize();

    expect(gateway.initializeCalls, 1);
    expect(viewModel.notifications.single.id, 'stored');
    expect(viewModel.authorizationStatus, AuthorizationStatus.authorized);
    expect(viewModel.token, 'test-token');
    expect(viewModel.unreadCount, 1);
    viewModel.dispose();
    await gateway.close();
  });

  test('foreground message is persisted unread and invokes callback', () async {
    final gateway = FakeMessagingGateway();
    final store = MemoryNotificationStore();
    ResearchNotification? callbackValue;
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: store,
      onForegroundNotification: (value) => callbackValue = value,
    );
    await viewModel.initialize();

    gateway.foregroundController.add(
      const RemoteMessage(
        messageId: 'foreground-1',
        notification: RemoteNotification(title: 'New research'),
      ),
    );
    await _flushEvents();

    expect(viewModel.notifications.single.id, 'foreground-1');
    expect(viewModel.unreadCount, 1);
    expect(store.values.single.id, 'foreground-1');
    expect(callbackValue?.id, 'foreground-1');
    viewModel.dispose();
    await gateway.close();
  });

  test(
    'opened message replaces duplicate, marks read and invokes callback',
    () async {
      final gateway = FakeMessagingGateway();
      final store = MemoryNotificationStore([
        _notification('same-message', isRead: false),
      ]);
      ResearchNotification? opened;
      final viewModel = NotificationCenterViewModel(
        userId: 'test-user',
        messaging: gateway,
        store: store,
        onNotificationOpened: (value) => opened = value,
      );
      await viewModel.initialize();

      gateway.openedController.add(
        const RemoteMessage(
          messageId: 'same-message',
          notification: RemoteNotification(title: 'Opened update'),
        ),
      );
      await _flushEvents();

      expect(viewModel.notifications, hasLength(1));
      expect(viewModel.notifications.single.title, 'Opened update');
      expect(viewModel.notifications.single.isRead, isTrue);
      expect(viewModel.unreadCount, 0);
      expect(opened?.id, 'same-message');
      viewModel.dispose();
      await gateway.close();
    },
  );

  test('initial message is handled as an opened notification', () async {
    final gateway = FakeMessagingGateway(
      initialMessage: const RemoteMessage(
        messageId: 'initial-1',
        data: {'title': 'Highly cited publication'},
      ),
    );
    var openedCount = 0;
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: MemoryNotificationStore(),
      onNotificationOpened: (_) => openedCount++,
    );

    await viewModel.initialize();

    expect(viewModel.notifications.single.id, 'initial-1');
    expect(viewModel.notifications.single.isRead, isTrue);
    expect(openedCount, 1);
    viewModel.dispose();
    await gateway.close();
  });

  test('permission request refreshes status and token', () async {
    final gateway = FakeMessagingGateway(
      currentStatus: AuthorizationStatus.denied,
      requestedStatus: AuthorizationStatus.authorized,
      currentToken: 'new-token',
    );
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: MemoryNotificationStore(),
    );
    await viewModel.initialize();

    await viewModel.requestPermission();

    expect(gateway.permissionCalls, 1);
    expect(viewModel.hasPermission, isTrue);
    expect(viewModel.token, 'new-token');
    viewModel.dispose();
    await gateway.close();
  });

  test(
    'token failure keeps listeners active and retry does not duplicate them',
    () async {
      final gateway = FakeMessagingGateway(
        currentStatus: AuthorizationStatus.authorized,
        tokenError: StateError('token unavailable'),
      );
      var foregroundCallbacks = 0;
      final viewModel = NotificationCenterViewModel(
        userId: 'test-user',
        messaging: gateway,
        store: MemoryNotificationStore(),
        onForegroundNotification: (_) => foregroundCallbacks++,
      );

      await viewModel.initialize();

      expect(viewModel.errorMessage, contains('token is not ready'));
      expect(viewModel.token, isNull);
      expect(gateway.foregroundController.hasListener, isTrue);
      gateway.foregroundController.add(
        const RemoteMessage(messageId: 'received-without-token'),
      );
      await _flushEvents();
      expect(viewModel.notifications.single.id, 'received-without-token');
      expect(foregroundCallbacks, 1);

      gateway
        ..tokenError = null
        ..currentToken = 'recovered-token';
      await viewModel.retryInitialization();
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.token, 'recovered-token');

      gateway.foregroundController.add(
        const RemoteMessage(messageId: 'received-after-retry'),
      );
      await _flushEvents();
      expect(foregroundCallbacks, 2);
      expect(gateway.foregroundStreamReads, 1);
      expect(gateway.openedStreamReads, 1);
      expect(gateway.tokenStreamReads, 1);
      viewModel.dispose();
      await gateway.close();
    },
  );

  test('in-memory notification list is trimmed immediately', () async {
    final gateway = FakeMessagingGateway();
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: MemoryNotificationStore(),
      maximumItems: 2,
    );
    await viewModel.initialize();

    for (var index = 0; index < 3; index++) {
      gateway.foregroundController.add(
        RemoteMessage(
          messageId: 'message-$index',
          sentTime: DateTime.utc(2026, 7, 15, 12, index),
        ),
      );
      await _flushEvents();
    }

    expect(viewModel.notifications, hasLength(2));
    expect(viewModel.notifications.map((item) => item.id), [
      'message-2',
      'message-1',
    ]);
    viewModel.dispose();
    await gateway.close();
  });

  test('mark read, mark all and clear persist each change', () async {
    final gateway = FakeMessagingGateway();
    final store = MemoryNotificationStore([
      _notification('one', isRead: false),
      _notification('two', isRead: false),
    ]);
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: store,
    );
    await viewModel.initialize();

    await viewModel.markAsRead('one');
    expect(viewModel.unreadCount, 1);
    await viewModel.markAllAsRead();
    expect(viewModel.unreadCount, 0);
    await viewModel.clearAll();
    expect(viewModel.notifications, isEmpty);
    expect(store.values, isEmpty);
    expect(store.saveCalls, 3);
    viewModel.dispose();
    await gateway.close();
  });

  test('dispose during initialize does not attach message listeners', () async {
    final initialization = Completer<void>();
    final gateway = FakeMessagingGateway(initialization: initialization.future);
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: MemoryNotificationStore(),
    );

    final initializeFuture = viewModel.initialize();
    viewModel.dispose();
    initialization.complete();
    await initializeFuture;

    expect(gateway.foregroundController.hasListener, isFalse);
    expect(gateway.openedController.hasListener, isFalse);
    expect(gateway.tokenController.hasListener, isFalse);
    await gateway.close();
  });
}

ResearchNotification _notification(String id, {required bool isRead}) {
  return ResearchNotification(
    id: id,
    title: 'Title $id',
    body: 'Body $id',
    receivedAt: DateTime(2026, 7, 15, 12),
    source: ResearchNotificationSource.background,
    isRead: isRead,
  );
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

NotificationSettings _settings(AuthorizationStatus status) {
  return NotificationSettings(
    alert: AppleNotificationSetting.notSupported,
    announcement: AppleNotificationSetting.notSupported,
    authorizationStatus: status,
    badge: AppleNotificationSetting.notSupported,
    carPlay: AppleNotificationSetting.notSupported,
    lockScreen: AppleNotificationSetting.notSupported,
    notificationCenter: AppleNotificationSetting.notSupported,
    showPreviews: AppleShowPreviewSetting.notSupported,
    timeSensitive: AppleNotificationSetting.notSupported,
    criticalAlert: AppleNotificationSetting.notSupported,
    sound: AppleNotificationSetting.notSupported,
    providesAppNotificationSettings: AppleNotificationSetting.notSupported,
  );
}

class FakeMessagingGateway implements MessagingGateway {
  FakeMessagingGateway({
    this.currentStatus = AuthorizationStatus.notDetermined,
    this.requestedStatus = AuthorizationStatus.denied,
    this.currentToken,
    this.initialMessage,
    this.initialization,
    this.tokenError,
  });

  final StreamController<RemoteMessage> foregroundController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> openedController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<String> tokenController =
      StreamController<String>.broadcast();

  AuthorizationStatus currentStatus;
  AuthorizationStatus requestedStatus;
  String? currentToken;
  RemoteMessage? initialMessage;
  Future<void>? initialization;
  Object? tokenError;
  int initializeCalls = 0;
  int permissionCalls = 0;
  int foregroundStreamReads = 0;
  int openedStreamReads = 0;
  int tokenStreamReads = 0;

  @override
  Stream<RemoteMessage> get foregroundMessages {
    foregroundStreamReads++;
    return foregroundController.stream;
  }

  @override
  Stream<RemoteMessage> get openedMessages {
    openedStreamReads++;
    return openedController.stream;
  }

  @override
  Stream<String> get tokenRefreshes {
    tokenStreamReads++;
    return tokenController.stream;
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      _settings(currentStatus);

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<String?> getToken() async {
    final error = tokenError;
    if (error != null) throw error;
    return currentToken;
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
    await initialization;
  }

  @override
  Future<NotificationSettings> requestPermission() async {
    permissionCalls++;
    currentStatus = requestedStatus;
    return _settings(requestedStatus);
  }

  Future<void> close() async {
    await foregroundController.close();
    await openedController.close();
    await tokenController.close();
  }
}

class MemoryNotificationStore implements NotificationStore {
  MemoryNotificationStore([List<ResearchNotification>? initial])
    : values = [...?initial];

  List<ResearchNotification> values;
  int saveCalls = 0;

  @override
  Future<List<ResearchNotification>> load() async => [...values];

  @override
  Future<void> save(List<ResearchNotification> notifications) async {
    saveCalls++;
    values = [...notifications];
  }

  @override
  Future<void> upsert(ResearchNotification notification) async {
    values = [
      notification,
      ...values.where((item) => item.id != notification.id),
    ];
  }
}
