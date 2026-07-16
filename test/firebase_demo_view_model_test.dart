import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/firebase/crashlytics_service.dart';
import 'package:journal_trend_analysis/firebase/remote_config_service.dart';
import 'package:journal_trend_analysis/viewmodels/firebase_demo_view_model.dart';

void main() {
  test('starts with current Remote Config values', () {
    final remoteConfig = FakeRemoteConfig(maxJournals: 12, maxKeywords: 8);
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: remoteConfig,
      crashlytics: FakeCrashlytics(),
    );

    expect(viewModel.maxJournals, 12);
    expect(viewModel.maxKeywords, 8);
    viewModel.dispose();
  });

  test('refresh activates and reads new Remote Config values', () async {
    final remoteConfig = FakeRemoteConfig(
      maxJournals: 10,
      maxKeywords: 10,
      activated: true,
      valuesAfterRefresh: const (15, 7),
    );
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: remoteConfig,
      crashlytics: FakeCrashlytics(),
    );

    await viewModel.refreshRemoteConfig();

    expect(remoteConfig.refreshCalls, 1);
    expect(viewModel.maxJournals, 15);
    expect(viewModel.maxKeywords, 7);
    expect(viewModel.remoteConfigMessage, contains('activate'));
    expect(viewModel.remoteConfigError, isNull);
    viewModel.dispose();
  });

  test('refresh reports success when fetched values are unchanged', () async {
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: FakeRemoteConfig(activated: false),
      crashlytics: FakeCrashlytics(),
    );

    await viewModel.refreshRemoteConfig();

    expect(viewModel.remoteConfigMessage, contains('unchanged'));
    viewModel.dispose();
  });

  test('refresh failure is surfaced without changing values', () async {
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: FakeRemoteConfig(refreshError: StateError('offline')),
      crashlytics: FakeCrashlytics(),
    );

    await viewModel.refreshRemoteConfig();

    expect(viewModel.maxJournals, 10);
    expect(viewModel.remoteConfigError, contains('Unable to refresh'));
    expect(viewModel.isRefreshingConfig, isFalse);
    viewModel.dispose();
  });

  test('duplicate refresh taps share one in-flight operation', () async {
    final completer = Completer<bool>();
    final remoteConfig = FakeRemoteConfig(refreshFuture: completer.future);
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: remoteConfig,
      crashlytics: FakeCrashlytics(),
    );

    final first = viewModel.refreshRemoteConfig();
    final second = viewModel.refreshRemoteConfig();
    expect(remoteConfig.refreshCalls, 1);
    completer.complete(false);
    await Future.wait([first, second]);
    viewModel.dispose();
  });

  test(
    'handled exception reports success and prevents duplicate taps',
    () async {
      final completer = Completer<void>();
      final crashlytics = FakeCrashlytics(handledFuture: completer.future);
      final viewModel = FirebaseDemoViewModel(
        remoteConfig: FakeRemoteConfig(),
        crashlytics: crashlytics,
      );

      final first = viewModel.recordHandledException();
      final second = viewModel.recordHandledException();
      expect(crashlytics.handledCalls, 1);
      completer.complete();
      await Future.wait([first, second]);

      expect(viewModel.crashlyticsMessage, contains('Handled exception'));
      expect(viewModel.crashlyticsError, isNull);
      viewModel.dispose();
    },
  );

  test('handled exception failure is safe and visible', () async {
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: FakeRemoteConfig(),
      crashlytics: FakeCrashlytics(handledError: StateError('unavailable')),
    );

    await viewModel.recordHandledException();

    expect(viewModel.crashlyticsError, contains('Unable to send'));
    expect(viewModel.isRecordingHandledException, isFalse);
    viewModel.dispose();
  });

  test('test crash is delegated only when explicitly requested', () async {
    final crashlytics = FakeCrashlytics();
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: FakeRemoteConfig(),
      crashlytics: crashlytics,
    );

    expect(crashlytics.crashCalls, 0);
    await viewModel.triggerTestCrash();
    expect(crashlytics.crashCalls, 1);
    viewModel.dispose();
  });

  test('dispose during async work does not notify listeners', () async {
    final completer = Completer<bool>();
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: FakeRemoteConfig(refreshFuture: completer.future),
      crashlytics: FakeCrashlytics(),
    );
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    final refresh = viewModel.refreshRemoteConfig();
    expect(notifications, 1);
    viewModel.dispose();
    completer.complete(false);
    await refresh;

    expect(notifications, 1);
  });
}

class FakeRemoteConfig implements RemoteConfigGateway {
  FakeRemoteConfig({
    this.maxJournals = 10,
    this.maxKeywords = 10,
    this.activated = false,
    this.valuesAfterRefresh,
    this.refreshError,
    this.refreshFuture,
  });

  @override
  int maxJournals;
  @override
  int maxKeywords;
  final bool activated;
  final (int, int)? valuesAfterRefresh;
  final Object? refreshError;
  final Future<bool>? refreshFuture;
  int refreshCalls = 0;

  @override
  Future<bool> refreshForDemo() async {
    refreshCalls++;
    if (refreshError != null) throw refreshError!;
    final result = await refreshFuture ?? activated;
    final values = valuesAfterRefresh;
    if (values != null) {
      maxJournals = values.$1;
      maxKeywords = values.$2;
    }
    return result;
  }
}

class FakeCrashlytics implements CrashlyticsGateway {
  FakeCrashlytics({this.handledFuture, this.handledError});

  final Future<void>? handledFuture;
  final Object? handledError;
  int handledCalls = 0;
  int crashCalls = 0;

  @override
  Future<void> recordHandledDemoException() async {
    handledCalls++;
    if (handledError != null) throw handledError!;
    await handledFuture;
  }

  @override
  Future<void> triggerTestCrash() async {
    crashCalls++;
  }
}
