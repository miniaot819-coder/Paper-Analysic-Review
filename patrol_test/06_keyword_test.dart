import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common.dart';

// Patrol discovers targets lexically, so this file owns TC06-TC07.
void main() {
  patrolTest(
    'TC06 Keywords Navigation shows statistics and keyword results',
    ($) async {
      await pumpJournalSearchApp($);
      await ensureSignedIn($);
      await searchKeywordsTopic($);

      await $(
        PatrolKeys.keywordsSummaryWorks,
      ).scrollTo(view: find.byKey(PatrolKeys.keywordsScreen));
      expect(integerAt($, PatrolKeys.keywordsSummaryWorks), greaterThan(0));
      expect(integerAt($, PatrolKeys.keywordsSummaryUnique), greaterThan(0));
      expectNonEmptyText($, PatrolKeys.keywordsSummaryTop);

      await $(
        PatrolKeys.keywordItem0,
      ).scrollTo(view: find.byKey(PatrolKeys.keywordsScreen));
      expect($(PatrolKeys.keywordItem0), findsOneWidget);
    },
    timeout: patrolTestTimeout,
  );

  patrolTest('TC07 Keyword Details shows keyword analysis', ($) async {
    await pumpJournalSearchApp($);
    await ensureSignedIn($);
    await searchKeywordsTopic($);

    await $(
      PatrolKeys.keywordItem0,
    ).scrollTo(view: find.byKey(PatrolKeys.keywordsScreen));
    await $(PatrolKeys.keywordItem0).tap();
    await $(PatrolKeys.keywordDetailScreen).waitUntilVisible();

    expectNonEmptyText($, PatrolKeys.keywordDetailName);
    expectNonEmptyText($, PatrolKeys.keywordDetailSummary);
    await $(
      PatrolKeys.keywordDetailTrend,
    ).scrollTo(view: find.byKey(PatrolKeys.keywordDetailScreen));
    expect($(PatrolKeys.keywordDetailTrend), findsOneWidget);
    await $(
      PatrolKeys.keywordDetailRelatedJournals,
    ).scrollTo(view: find.byKey(PatrolKeys.keywordDetailScreen));
    expect($(PatrolKeys.keywordDetailRelatedJournals), findsOneWidget);
    expect($(PatrolKeys.keywordDetailJournal0), findsOneWidget);
    await $(
      PatrolKeys.keywordDetailTopAuthors,
    ).scrollTo(view: find.byKey(PatrolKeys.keywordDetailScreen));
    expect($(PatrolKeys.keywordDetailTopAuthors), findsOneWidget);
    expect($(PatrolKeys.keywordDetailAuthor0), findsOneWidget);
    await $(
      PatrolKeys.keywordDetailRelatedPublications,
    ).scrollTo(view: find.byKey(PatrolKeys.keywordDetailScreen));
    expect($(PatrolKeys.keywordDetailRelatedPublications), findsOneWidget);
    await $(
      PatrolKeys.keywordDetailPublication0,
    ).scrollTo(view: find.byKey(PatrolKeys.keywordDetailScreen));
    expect($(PatrolKeys.keywordDetailPublication0), findsOneWidget);
  }, timeout: patrolTestTimeout);
}
