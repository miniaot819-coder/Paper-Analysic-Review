import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/screens/login_screen.dart';

void main() {
  testWidgets('starts Google sign-in and prevents duplicate taps', (
    WidgetTester tester,
  ) async {
    final completer = Completer<void>();
    var signInCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onSignInWithGoogle: () {
            signInCalls += 1;
            return completer.future;
          },
        ),
      ),
    );

    expect(find.text('Journal Trend Analyzer'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pump();

    expect(signInCalls, 1);
    expect(find.text('Signing in...'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('shows a friendly message when Google sign-in fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onSignInWithGoogle: () async {
            throw StateError('test sign-in failure');
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error_message')), findsOneWidget);
    expect(
      find.text('Could not sign in with Google. Please try again.'),
      findsOneWidget,
    );
  });
}
