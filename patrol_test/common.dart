import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:journal_trend_analysis/firebase/firebase_bootstrap.dart';
import 'package:journal_trend_analysis/main.dart';

const String patrolGoogleAccount = String.fromEnvironment(
  'PATROL_GOOGLE_ACCOUNT',
);

const String patrolTopic = 'Machine Learning';
const Duration authTimeout = Duration(seconds: 60);
const Duration openAlexAttemptTimeout = Duration(seconds: 60);
const Duration firebaseActionTimeout = Duration(minutes: 3);
const Timeout patrolTestTimeout = Timeout(Duration(minutes: 10));

abstract final class PatrolKeys {
  static const googleSignInButton = Key('google_sign_in_button');
  static const homeScreen = Key('home_screen');
  static const homeTab = Key('home_tab');
  static const homeTopicSearchField = Key('home_topic_search_field');
  static const homeTopicSearchButton = Key('home_topic_search_button');
  static const mostInfluentialPublicationCard = Key(
    'most_influential_publication_card',
  );
  static const publicationDetailScreen = Key('publication_detail_screen');
  static const publicationDetailTitle = Key('publication_detail_title');
  static const publicationDetailYear = Key('publication_detail_year');
  static const publicationDetailJournal = Key('publication_detail_journal');
  static const publicationDetailCitationCount = Key(
    'publication_detail_citation_count',
  );
  static const publicationDetailAuthors = Key('publication_detail_authors');

  static const journalsTab = Key('journals_tab');
  static const journalsScreen = Key('journals_screen');
  static const journalsTopicSearchField = Key('journals_topic_search_field');
  static const journalsTopicSearchButton = Key('journals_topic_search_button');
  static const journalItem0 = Key('journal_item_0');
  static const journalsSummaryWorks = Key('journals_summary_works');
  static const journalsSummaryJournals = Key('journals_summary_journals');
  static const journalsSummaryCitations = Key('journals_summary_citations');
  static const journalDetailScreen = Key('journal_detail_screen');
  static const journalDetailName = Key('journal_detail_name');
  static const journalDetailPublicationCount = Key(
    'journal_detail_publication_count',
  );
  static const journalDetailPublication0 = Key('journal_detail_publication_0');
  static const journalDetailRelatedPublications = Key(
    'journal_detail_related_publications',
  );

  static const keywordsTab = Key('keywords_tab');
  static const keywordsScreen = Key('keywords_screen');
  static const keywordsTopicSearchField = Key('keywords_topic_search_field');
  static const keywordsTopicSearchButton = Key('keywords_topic_search_button');
  static const keywordItem0 = Key('keyword_item_0');
  static const keywordsSummaryWorks = Key('keywords_summary_works');
  static const keywordsSummaryUnique = Key('keywords_summary_unique');
  static const keywordsSummaryTop = Key('keywords_summary_top');
  static const keywordDetailScreen = Key('keyword_detail_screen');
  static const keywordDetailName = Key('keyword_detail_name');
  static const keywordDetailSummary = Key('keyword_detail_summary');
  static const keywordDetailTrend = Key('keyword_detail_trend');
  static const keywordDetailRelatedJournals = Key(
    'keyword_detail_related_journals',
  );
  static const keywordDetailTopAuthors = Key('keyword_detail_top_authors');
  static const keywordDetailRelatedPublications = Key(
    'keyword_detail_related_publications',
  );
  static const keywordDetailJournal0 = Key('keyword_detail_journal_0');
  static const keywordDetailAuthor0 = Key('keyword_detail_author_0');
  static const keywordDetailPublication0 = Key('keyword_detail_publication_0');

  static const profileTab = Key('profile_tab');
  static const profileScreen = Key('profile_screen');
  static const profileUserName = Key('profile_user_name');
  static const profileUserEmail = Key('profile_user_email');
  static const exportPdfButton = Key('export_pdf_button');
  static const reportExportSuccess = Key('report_export_success');
  static const reportExportError = Key('report_export_error');
  static const reportDownloadUrl = Key('report_download_url');
  static const refreshRemoteConfigButton = Key('refresh_remote_config_button');
  static const remoteConfigSuccess = Key('remote_config_success');
  static const remoteConfigError = Key('remote_config_error');
  static const maxJournalsConfigValue = Key('max_journals_config_value');
  static const maxKeywordsConfigValue = Key('max_keywords_config_value');
  static const profileSignOutButton = Key('profile_sign_out_button');

  static const openAlexLoadedStatus = Key('openalex_loaded_status');
}

Future<void> pumpJournalSearchApp(PatrolIntegrationTester $) async {
  final firebaseEnabled = await FirebaseBootstrap.initialize();

  // Deliberately pump the app widget instead of calling main(). The production
  // main() installs Crashlytics global error handlers, which must not intercept
  // exceptions raised by the Patrol test framework.
  await $.pumpWidgetAndSettle(
    JournalSearchApp(firebaseEnabled: firebaseEnabled),
  );

  expect(
    firebaseEnabled,
    isTrue,
    reason:
        'Firebase initialization failed: '
        '${FirebaseBootstrap.initializationError}',
  );
}

Future<void> ensureSignedIn(PatrolIntegrationTester $) async {
  if ($(PatrolKeys.homeScreen).visible) return;

  await $(PatrolKeys.googleSignInButton).waitUntilVisible(timeout: authTimeout);

  await $(PatrolKeys.googleSignInButton).tap();
  await $.pump(const Duration(seconds: 2));

  if (!$(PatrolKeys.homeScreen).visible) {
    final configuredAccount = patrolGoogleAccount.trim();
    final accountSelector = configuredAccount.isEmpty
        ? Selector(textContains: '@', instance: 0)
        : Selector(text: configuredAccount);
    Object? chooserError;
    try {
      await $.platform.mobile.tap(
        accountSelector,
        timeout: const Duration(seconds: 15),
      );
    } catch (error) {
      // Google Sign-In can reuse the previously authorized account and skip
      // the native chooser. The Home assertion below remains authoritative.
      chooserError = error;
    }

    try {
      await $(PatrolKeys.homeScreen).waitUntilVisible(timeout: authTimeout);
    } catch (_) {
      fail(
        'Google Sign-In did not reach Home. Make sure '
        '${configuredAccount.isEmpty ? 'a Google test account' : configuredAccount} '
        'is already added to the emulator and selectable in the Google account '
        'chooser. Native chooser result: '
        '$chooserError',
      );
    }
  }

  expect($(PatrolKeys.homeScreen), findsOneWidget);
}

Future<void> ensureSignedOut(PatrolIntegrationTester $) async {
  if ($(PatrolKeys.googleSignInButton).visible) return;

  await openProfile($);
  await $(
    PatrolKeys.profileSignOutButton,
  ).scrollTo(view: find.byKey(PatrolKeys.profileScreen));
  await $(PatrolKeys.profileSignOutButton).tap();
  await $(PatrolKeys.googleSignInButton).waitUntilVisible(timeout: authTimeout);
}

Future<void> openHome(PatrolIntegrationTester $) async {
  await $(PatrolKeys.homeTab).tap();
  await $(PatrolKeys.homeScreen).waitUntilVisible();
}

Future<void> openJournals(PatrolIntegrationTester $) async {
  await $(PatrolKeys.journalsTab).tap();
  await $(PatrolKeys.journalsScreen).waitUntilVisible();
}

Future<void> openKeywords(PatrolIntegrationTester $) async {
  await $(PatrolKeys.keywordsTab).tap();
  await $(PatrolKeys.keywordsScreen).waitUntilVisible();
}

Future<void> openProfile(PatrolIntegrationTester $) async {
  await $(PatrolKeys.profileTab).tap();
  await $(PatrolKeys.profileScreen).waitUntilVisible();
}

Future<void> searchHomeTopic(PatrolIntegrationTester $) async {
  await openHome($);
  await $(PatrolKeys.homeTopicSearchField).enterText(patrolTopic);
  await _submitOpenAlexSearch($, buttonKey: PatrolKeys.homeTopicSearchButton);
}

Future<void> searchJournalsTopic(PatrolIntegrationTester $) async {
  await openJournals($);
  await $(PatrolKeys.journalsTopicSearchField).enterText(patrolTopic);
  // Journal rows are produced by ListView.builder and do not exist in the
  // element tree until the list is scrolled. Wait for the loaded-state widget;
  // each scenario then uses scrollTo() to lazily build the first row.
  await _submitOpenAlexSearch(
    $,
    buttonKey: PatrolKeys.journalsTopicSearchButton,
  );
}

Future<void> searchKeywordsTopic(PatrolIntegrationTester $) async {
  await openKeywords($);
  await $(PatrolKeys.keywordsTopicSearchField).enterText(patrolTopic);
  await _submitOpenAlexSearch(
    $,
    buttonKey: PatrolKeys.keywordsTopicSearchButton,
  );
}

Future<void> _submitOpenAlexSearch(
  PatrolIntegrationTester $, {
  required Key buttonKey,
}) async {
  // Each analysis tab starts its own default OpenAlex request on first render.
  // Wait for that request to finish before submitting patrolTopic; tapping a
  // disabled button otherwise looks successful but invokes no callback.
  await _waitForSearchButtonEnabled($, buttonKey);
  await $(buttonKey).tap();
  final deadline = DateTime.now().add(openAlexAttemptTimeout);

  while (DateTime.now().isBefore(deadline)) {
    if ($(PatrolKeys.openAlexLoadedStatus).exists) return;

    final buttonFinder = find.byKey(buttonKey);
    if (buttonFinder.evaluate().isNotEmpty) {
      final button = $.tester.widget<FilledButton>(buttonFinder);
      // The service owns the bounded HTTP retry policy. Becoming enabled
      // without loaded results means that policy was exhausted, so fail this
      // scenario instead of stacking another request loop in Patrol.
      if (button.onPressed != null) {
        fail('OpenAlex returned no loaded results for $patrolTopic.');
      }
    }
    await $.pump(const Duration(milliseconds: 500));
  }

  fail(
    'OpenAlex did not expose loaded publication results within '
    '$openAlexAttemptTimeout for $patrolTopic.',
  );
}

Future<void> _waitForSearchButtonEnabled(
  PatrolIntegrationTester $,
  Key buttonKey,
) async {
  final deadline = DateTime.now().add(openAlexAttemptTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final buttonFinder = find.byKey(buttonKey);
    if (buttonFinder.evaluate().isNotEmpty) {
      final button = $.tester.widget<FilledButton>(buttonFinder);
      if (button.onPressed != null) return;
    }
    await $.pump(const Duration(milliseconds: 500));
  }
  fail('Search button $buttonKey stayed disabled for $openAlexAttemptTimeout.');
}

String textAt(PatrolIntegrationTester $, Key key) {
  final widget = $.tester.widget<Widget>(find.byKey(key));
  return switch (widget) {
    Text(:final data) => data?.trim() ?? '',
    SelectableText(:final data) => data?.trim() ?? '',
    _ => throw TestFailure(
      'Expected ${key.toString()} to be a Text or SelectableText widget, '
      'but found ${widget.runtimeType}.',
    ),
  };
}

void expectNonEmptyText(PatrolIntegrationTester $, Key key) {
  expect(
    textAt($, key),
    isNotEmpty,
    reason: '${key.toString()} must expose non-empty user-visible text.',
  );
}

int integerAt(PatrolIntegrationTester $, Key key) {
  final rawValue = textAt($, key);
  final value = int.tryParse(rawValue);
  if (value == null) {
    throw TestFailure(
      '${key.toString()} must expose an integer, but found "$rawValue".',
    );
  }
  return value;
}

Future<void> waitForReportExportSuccess(PatrolIntegrationTester $) async {
  final deadline = DateTime.now().add(firebaseActionTimeout);
  while (DateTime.now().isBefore(deadline)) {
    if ($(PatrolKeys.reportExportSuccess).exists) return;
    if ($(PatrolKeys.reportExportError).exists) {
      fail('PDF export failed before reaching Firebase Storage.');
    }
    await $.pump(const Duration(milliseconds: 500));
  }
  fail('PDF export did not finish within $firebaseActionTimeout.');
}

Future<void> waitForRemoteConfigSuccess(PatrolIntegrationTester $) async {
  final deadline = DateTime.now().add(firebaseActionTimeout);
  while (DateTime.now().isBefore(deadline)) {
    if ($(PatrolKeys.remoteConfigSuccess).exists) return;
    if ($(PatrolKeys.remoteConfigError).exists) {
      fail('Remote Config fetch-and-activate returned an error.');
    }
    await $.pump(const Duration(milliseconds: 300));
  }
  fail('Remote Config did not finish within $firebaseActionTimeout.');
}
