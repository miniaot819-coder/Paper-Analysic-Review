import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common.dart';

// Keep TC11 in the last lexically sorted Patrol target.
void main() {
  patrolTest('TC11 Logout returns to Login', ($) async {
    await pumpJournalSearchApp($);
    await ensureSignedIn($);
    await openProfile($);

    await $(
      PatrolKeys.profileSignOutButton,
    ).scrollTo(view: find.byKey(PatrolKeys.profileScreen));
    await $(PatrolKeys.profileSignOutButton).tap();

    await $(
      PatrolKeys.googleSignInButton,
    ).waitUntilVisible(timeout: authTimeout);
    expect($(PatrolKeys.googleSignInButton), findsOneWidget);
  }, timeout: patrolTestTimeout);
}
