import 'package:flutter/material.dart';

import '../models/journal_insight.dart';
import '../models/keyword_insight.dart';
import '../screens/journal_detail_screen.dart';
import '../screens/keyword_detail_screen.dart';

class AnalysisRoutes {
  AnalysisRoutes._();

  static const String journalDetailName = '/journal-detail';
  static const String keywordDetailName = '/keyword-detail';

  static Route<void> journalDetail(JournalInsight journal) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: journalDetailName,
        arguments: journal.id ?? journal.name,
      ),
      builder: (_) => JournalDetailScreen(journal: journal),
    );
  }

  static Route<void> keywordDetail(KeywordInsight keyword) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: keywordDetailName, arguments: keyword.name),
      builder: (_) => KeywordDetailScreen(keyword: keyword),
    );
  }
}
