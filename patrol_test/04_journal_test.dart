import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common.dart';

// Patrol discovers targets lexically, so this file owns TC04-TC05.
void main() {
  patrolTest(
    'TC04 Journals Navigation shows statistics and journal results',
    ($) async {
      await pumpJournalSearchApp($);
      await ensureSignedIn($);
      await searchJournalsTopic($);

      await $(
        PatrolKeys.journalsSummaryWorks,
      ).scrollTo(view: find.byKey(PatrolKeys.journalsScreen));
      expect(integerAt($, PatrolKeys.journalsSummaryWorks), greaterThan(0));
      expect(integerAt($, PatrolKeys.journalsSummaryJournals), greaterThan(0));
      expect(
        integerAt($, PatrolKeys.journalsSummaryCitations),
        greaterThanOrEqualTo(0),
      );

      await $(
        PatrolKeys.journalItem0,
      ).scrollTo(view: find.byKey(PatrolKeys.journalsScreen));
      expect($(PatrolKeys.journalItem0), findsOneWidget);
    },
    timeout: patrolTestTimeout,
  );

  patrolTest('TC05 Journal Details shows the selected journal', ($) async {
    await pumpJournalSearchApp($);
    await ensureSignedIn($);
    await searchJournalsTopic($);

    await $(
      PatrolKeys.journalItem0,
    ).scrollTo(view: find.byKey(PatrolKeys.journalsScreen));
    await $(PatrolKeys.journalItem0).tap();
    await $(PatrolKeys.journalDetailScreen).waitUntilVisible();

    expectNonEmptyText($, PatrolKeys.journalDetailName);
    expect(
      integerAt($, PatrolKeys.journalDetailPublicationCount),
      greaterThan(0),
    );
    await $(
      PatrolKeys.journalDetailRelatedPublications,
    ).scrollTo(view: find.byKey(PatrolKeys.journalDetailScreen));
    expect($(PatrolKeys.journalDetailRelatedPublications), findsOneWidget);
    await $(
      PatrolKeys.journalDetailPublication0,
    ).scrollTo(view: find.byKey(PatrolKeys.journalDetailScreen));
    expect($(PatrolKeys.journalDetailPublication0), findsOneWidget);
  }, timeout: patrolTestTimeout);
}
