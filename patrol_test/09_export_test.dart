import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common.dart';

// Patrol discovers targets lexically, so this file owns TC09.
void main() {
  patrolTest(
    'TC09 PDF Export generates and uploads a report to Firebase Storage',
    ($) async {
      await pumpJournalSearchApp($);
      await ensureSignedIn($);
      await searchHomeTopic($);
      await openProfile($);

      await $(
        PatrolKeys.exportPdfButton,
      ).scrollTo(view: find.byKey(PatrolKeys.profileScreen));
      await $(PatrolKeys.exportPdfButton).tap();
      await waitForReportExportSuccess($);

      expect($(PatrolKeys.reportExportSuccess), findsOneWidget);
      expectNonEmptyText($, PatrolKeys.reportDownloadUrl);
      final reportUri = Uri.tryParse(textAt($, PatrolKeys.reportDownloadUrl));
      expect(reportUri, isNotNull);
      expect(reportUri!.scheme, 'https');
      expect(reportUri.host, isNotEmpty);
    },
    timeout: patrolTestTimeout,
  );
}
