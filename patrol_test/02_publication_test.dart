import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common.dart';

// Patrol discovers targets lexically, so this file owns TC02-TC03.
void main() {
  patrolTest('TC02 Topic Search returns publication results', ($) async {
    await pumpJournalSearchApp($);
    await ensureSignedIn($);
    await searchHomeTopic($);

    await $(
      PatrolKeys.mostInfluentialPublicationCard,
    ).scrollTo(view: find.byKey(PatrolKeys.homeScreen));
    expect($(PatrolKeys.mostInfluentialPublicationCard), findsOneWidget);
  }, timeout: patrolTestTimeout);

  patrolTest(
    'TC03 Publication Details shows publication information',
    ($) async {
      await pumpJournalSearchApp($);
      await ensureSignedIn($);
      await searchHomeTopic($);

      await $(
        PatrolKeys.mostInfluentialPublicationCard,
      ).scrollTo(view: find.byKey(PatrolKeys.homeScreen));
      await $(PatrolKeys.mostInfluentialPublicationCard).tap();
      await $(PatrolKeys.publicationDetailScreen).waitUntilVisible();

      expectNonEmptyText($, PatrolKeys.publicationDetailTitle);
      expectNonEmptyText($, PatrolKeys.publicationDetailYear);
      expectNonEmptyText($, PatrolKeys.publicationDetailJournal);
      expectNonEmptyText($, PatrolKeys.publicationDetailAuthors);
      expect(textAt($, PatrolKeys.publicationDetailAuthors), isNot('N/A'));
      expect(
        integerAt($, PatrolKeys.publicationDetailCitationCount),
        greaterThanOrEqualTo(0),
      );
    },
    timeout: patrolTestTimeout,
  );
}
