import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsTrackingService {
  AnalyticsTrackingService._();

  static final AnalyticsTrackingService instance = AnalyticsTrackingService._();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static const loginEvent = 'login';
  static const searchTopicEvent = 'search_topic';
  static const viewPublicationEvent = 'view_publication';
  static const viewJournalEvent = 'view_journal';
  static const viewKeywordEvent = 'view_keyword';
  static const exportPdfEvent = 'export_pdf';
  static const logoutEvent = 'logout';
  static const maxStringParameterLength = 100;

  static const requiredEventNames = <String>{
    loginEvent,
    searchTopicEvent,
    viewPublicationEvent,
    viewJournalEvent,
    viewKeywordEvent,
    exportPdfEvent,
    logoutEvent,
  };

  Future<void> logAppBootstrap() {
    return _logEvent(name: 'app_bootstrap');
  }

  Future<void> logLogin() {
    return _logEvent(name: loginEvent);
  }

  Future<void> logSearchTopic(String keyword) {
    return _logEvent(name: searchTopicEvent, parameters: {'keyword': keyword});
  }

  Future<void> logViewPublication({required String title, required int year}) {
    return _logEvent(
      name: viewPublicationEvent,
      parameters: {'publication_title': title, 'publication_year': year},
    );
  }

  Future<void> logViewJournal(String journalName) {
    return _logEvent(
      name: viewJournalEvent,
      parameters: {'journal_name': journalName},
    );
  }

  Future<void> logViewKeyword(String keyword) {
    return _logEvent(name: viewKeywordEvent, parameters: {'keyword': keyword});
  }

  Future<void> logExportPdf(String topic) {
    return _logEvent(name: exportPdfEvent, parameters: {'topic': topic});
  }

  Future<void> logLogout() {
    return _logEvent(name: logoutEvent);
  }

  Future<void> _logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: _normalizeParameters(parameters),
      );
    } catch (_) {
      // Analytics must not block core app flows while Firebase is unavailable.
    }
  }

  static Map<String, Object>? _normalizeParameters(
    Map<String, Object>? parameters,
  ) {
    if (parameters == null) return null;
    return parameters.map(
      (key, value) => MapEntry(
        key,
        value is String ? normalizeStringParameter(value) : value,
      ),
    );
  }

  @visibleForTesting
  static String normalizeStringParameter(String value) {
    final normalized = value.trim();
    return String.fromCharCodes(
      normalized.runes.take(maxStringParameterLength),
    );
  }
}
