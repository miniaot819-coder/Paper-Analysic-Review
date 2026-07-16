import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journal_trend_analysis/main.dart';
import 'package:journal_trend_analysis/screens/dashboard_screen.dart';
import 'package:journal_trend_analysis/screens/journals_screen.dart';
import 'package:journal_trend_analysis/screens/keywords_screen.dart';

void main() {
  testWidgets('renders and navigates across the required tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MainShell(firebaseEnabled: false, userId: null)),
    );

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Journals'), findsOneWidget);
    expect(find.text('Keywords'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.byKey(const Key('journals_tab')));
    await tester.pump();

    expect(find.byType(JournalsScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('keywords_tab')));
    await tester.pump();

    expect(find.byType(KeywordsScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_tab')));
    await tester.pump();

    expect(
      find.text('Firebase is disabled in this test environment.'),
      findsOneWidget,
    );
  });

  testWidgets('blocks protected tabs when Firebase initialization fails', (
    WidgetTester tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      JournalSearchApp(
        firebaseEnabled: false,
        initializeFirebase: () async {
          retries += 1;
          return false;
        },
      ),
    );

    expect(
      find.byKey(const Key('firebase_initialization_error_screen')),
      findsOneWidget,
    );
    expect(find.byType(MainShell), findsNothing);

    await tester.tap(
      find.byKey(const Key('retry_firebase_initialization_button')),
    );
    await tester.pumpAndSettle();

    expect(retries, 1);
    expect(find.byType(MainShell), findsNothing);
  });
}
