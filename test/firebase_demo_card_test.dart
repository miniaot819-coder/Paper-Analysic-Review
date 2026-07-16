import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/firebase/crashlytics_service.dart';
import 'package:journal_trend_analysis/firebase/remote_config_service.dart';
import 'package:journal_trend_analysis/viewmodels/firebase_demo_view_model.dart';
import 'package:journal_trend_analysis/widgets/firebase_demo_card.dart';

void main() {
  testWidgets('shows both Remote Config values and refreshes them', (
    tester,
  ) async {
    final remoteConfig = WidgetRemoteConfig();
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: remoteConfig,
      crashlytics: WidgetCrashlytics(),
    );
    await tester.pumpWidget(_app(viewModel));

    expect(find.byKey(const Key('max_journals_config')), findsOneWidget);
    expect(find.byKey(const Key('max_keywords_config')), findsOneWidget);
    expect(find.text('10'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('refresh_remote_config_button')));
    await tester.pumpAndSettle();

    expect(find.text('14'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.byKey(const Key('remote_config_success')), findsOneWidget);
    viewModel.dispose();
  });

  testWidgets('handled exception does not close app and shows success', (
    tester,
  ) async {
    final crashlytics = WidgetCrashlytics();
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: WidgetRemoteConfig(),
      crashlytics: crashlytics,
    );
    await tester.pumpWidget(_app(viewModel));

    await tester.tap(find.byKey(const Key('record_handled_exception_button')));
    await tester.pumpAndSettle();

    expect(crashlytics.handledCalls, 1);
    expect(find.byKey(const Key('crashlytics_success')), findsOneWidget);
    expect(find.byKey(const Key('firebase_demo_card')), findsOneWidget);
    viewModel.dispose();
  });

  testWidgets('test crash requires confirmation and cancel is safe', (
    tester,
  ) async {
    final crashlytics = WidgetCrashlytics();
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: WidgetRemoteConfig(),
      crashlytics: crashlytics,
    );
    await tester.pumpWidget(_app(viewModel));

    await tester.tap(find.byKey(const Key('test_crash_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('test_crash_confirmation_dialog')),
      findsOneWidget,
    );
    expect(crashlytics.crashCalls, 0);

    await tester.tap(find.byKey(const Key('cancel_test_crash_button')));
    await tester.pumpAndSettle();
    expect(crashlytics.crashCalls, 0);
    viewModel.dispose();
  });

  testWidgets('confirmed test crash calls the injected crash gateway', (
    tester,
  ) async {
    final crashlytics = WidgetCrashlytics();
    final viewModel = FirebaseDemoViewModel(
      remoteConfig: WidgetRemoteConfig(),
      crashlytics: crashlytics,
    );
    await tester.pumpWidget(_app(viewModel));

    await tester.tap(find.byKey(const Key('test_crash_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_test_crash_button')));
    await tester.pumpAndSettle();

    expect(crashlytics.crashCalls, 1);
    viewModel.dispose();
  });
}

Widget _app(FirebaseDemoViewModel viewModel) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: FirebaseDemoCard(viewModel: viewModel),
      ),
    ),
  );
}

class WidgetRemoteConfig implements RemoteConfigGateway {
  @override
  int maxJournals = 10;
  @override
  int maxKeywords = 10;

  @override
  Future<bool> refreshForDemo() async {
    maxJournals = 14;
    maxKeywords = 6;
    return true;
  }
}

class WidgetCrashlytics implements CrashlyticsGateway {
  int handledCalls = 0;
  int crashCalls = 0;

  @override
  Future<void> recordHandledDemoException() async {
    handledCalls++;
  }

  @override
  Future<void> triggerTestCrash() async {
    crashCalls++;
  }
}
