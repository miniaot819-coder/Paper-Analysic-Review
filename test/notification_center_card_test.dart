import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/firebase/messaging_service.dart';
import 'package:journal_trend_analysis/models/research_notification.dart';
import 'package:journal_trend_analysis/services/notification_store.dart';
import 'package:journal_trend_analysis/viewmodels/notification_center_view_model.dart';
import 'package:journal_trend_analysis/widgets/notification_center_card.dart';

void main() {
  testWidgets('shows permission action and empty state', (tester) async {
    final gateway = _WidgetMessagingGateway(AuthorizationStatus.notDetermined);
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: _WidgetStore(),
    );
    await viewModel.initialize();

    await tester.pumpWidget(_app(viewModel));

    expect(find.byKey(const Key('notification_center')), findsOneWidget);
    expect(
      find.byKey(const Key('request_notification_permission_button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('notification_empty_state')), findsOneWidget);
    viewModel.dispose();
    await gateway.close();
  });

  testWidgets('shows unread notification and marks it read', (tester) async {
    final gateway = _WidgetMessagingGateway(AuthorizationStatus.authorized);
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: _WidgetStore([
        ResearchNotification(
          id: 'widget-message',
          title: 'Trending topic',
          body: 'Quantum computing publications are increasing.',
          receivedAt: DateTime(2026, 7, 15, 20, 5),
          source: ResearchNotificationSource.background,
          isRead: false,
          topic: 'Quantum computing',
        ),
      ]),
    );
    await viewModel.initialize();

    await tester.pumpWidget(_app(viewModel));

    expect(find.text('Trending topic'), findsOneWidget);
    expect(find.text('Topic: Quantum computing'), findsOneWidget);
    expect(find.byKey(const Key('notification_unread_count')), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification_widget-message')));
    await tester.pump();
    expect(viewModel.unreadCount, 0);
    viewModel.dispose();
    await gateway.close();
  });

  testWidgets('shows notification setup error and retries token registration', (
    tester,
  ) async {
    final gateway = _WidgetMessagingGateway(
      AuthorizationStatus.authorized,
      failToken: true,
    );
    final viewModel = NotificationCenterViewModel(
      userId: 'test-user',
      messaging: gateway,
      store: _WidgetStore(),
    );
    await viewModel.initialize();
    await tester.pumpWidget(_app(viewModel));

    expect(find.byKey(const Key('notification_error')), findsOneWidget);
    expect(
      find.byKey(const Key('retry_notification_initialization_button')),
      findsOneWidget,
    );

    gateway.failToken = false;
    await tester.tap(
      find.byKey(const Key('retry_notification_initialization_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_error')), findsNothing);
    expect(find.byKey(const Key('copy_fcm_token_button')), findsOneWidget);
    expect(viewModel.token, 'widget-token');
    viewModel.dispose();
    await gateway.close();
  });
}

Widget _app(NotificationCenterViewModel viewModel) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: NotificationCenterCard(viewModel: viewModel),
      ),
    ),
  );
}

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

class _WidgetMessagingGateway implements MessagingGateway {
  _WidgetMessagingGateway(this.status, {this.failToken = false});

  final AuthorizationStatus status;
  bool failToken;
  final foreground = StreamController<RemoteMessage>.broadcast();
  final opened = StreamController<RemoteMessage>.broadcast();
  final tokens = StreamController<String>.broadcast();

  @override
  Stream<RemoteMessage> get foregroundMessages => foreground.stream;
  @override
  Stream<RemoteMessage> get openedMessages => opened.stream;
  @override
  Stream<String> get tokenRefreshes => tokens.stream;
  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      _settings(status);
  @override
  Future<RemoteMessage?> getInitialMessage() async => null;
  @override
  Future<String?> getToken() async {
    if (failToken) throw StateError('token unavailable');
    return status == AuthorizationStatus.authorized ? 'widget-token' : null;
  }

  @override
  Future<void> initialize() async {}
  @override
  Future<NotificationSettings> requestPermission() async => _settings(status);

  Future<void> close() async {
    await foreground.close();
    await opened.close();
    await tokens.close();
  }
}

class _WidgetStore implements NotificationStore {
  _WidgetStore([List<ResearchNotification>? values]) : values = [...?values];

  List<ResearchNotification> values;

  @override
  Future<List<ResearchNotification>> load() async => [...values];
  @override
  Future<void> save(List<ResearchNotification> notifications) async {
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
