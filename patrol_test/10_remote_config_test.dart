import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common.dart';

// Patrol discovers targets lexically, so this file owns TC10.
void main() {
  patrolTest(
    'TC10 Remote Config retrieves valid display limits',
    ($) async {
      await pumpJournalSearchApp($);
      await ensureSignedIn($);
      await openProfile($);

      await $(
        PatrolKeys.refreshRemoteConfigButton,
      ).scrollTo(view: find.byKey(PatrolKeys.profileScreen));
      await $(PatrolKeys.refreshRemoteConfigButton).tap();
      await waitForRemoteConfigSuccess($);

      final maxJournals = int.tryParse(
        textAt($, PatrolKeys.maxJournalsConfigValue),
      );
      final maxKeywords = int.tryParse(
        textAt($, PatrolKeys.maxKeywordsConfigValue),
      );
      expect(maxJournals, isNotNull);
      expect(maxJournals!, greaterThan(0));
      expect(maxKeywords, isNotNull);
      expect(maxKeywords!, greaterThan(0));
      expect($(PatrolKeys.remoteConfigSuccess), findsOneWidget);
    },
    timeout: patrolTestTimeout,
  );
}
