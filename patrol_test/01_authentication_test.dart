import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common.dart';

// Keep TC01 in the first lexically sorted Patrol target.
void main() {
  patrolTest('TC01 Google Sign-In reaches Home', ($) async {
    await pumpJournalSearchApp($);
    await ensureSignedOut($);
    await ensureSignedIn($);

    expect($(PatrolKeys.homeScreen), findsOneWidget);
  }, timeout: patrolTestTimeout);
}
