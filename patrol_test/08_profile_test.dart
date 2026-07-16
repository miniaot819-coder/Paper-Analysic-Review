import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common.dart';

// Patrol discovers targets lexically, so this file owns TC08.
void main() {
  patrolTest(
    'TC08 Profile Navigation shows authenticated user information',
    ($) async {
      await pumpJournalSearchApp($);
      await ensureSignedIn($);
      await openProfile($);

      expectNonEmptyText($, PatrolKeys.profileUserName);
      expectNonEmptyText($, PatrolKeys.profileUserEmail);
      final displayedEmail = textAt(
        $,
        PatrolKeys.profileUserEmail,
      ).toLowerCase();
      final configuredAccount = patrolGoogleAccount.trim().toLowerCase();
      if (configuredAccount.isEmpty) {
        expect(
          displayedEmail,
          contains('@'),
          reason: 'Profile must expose the signed-in Google account email.',
        );
      } else {
        expect(
          displayedEmail,
          configuredAccount,
          reason:
              'Profile must belong to the configured Patrol Google account.',
        );
      }
    },
    timeout: patrolTestTimeout,
  );
}
