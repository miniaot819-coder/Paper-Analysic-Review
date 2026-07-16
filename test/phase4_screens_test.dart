import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/models/journal_insight.dart';
import 'package:journal_trend_analysis/models/keyword_insight.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/models/trend_data.dart';
import 'package:journal_trend_analysis/screens/journal_detail_screen.dart';
import 'package:journal_trend_analysis/screens/keyword_detail_screen.dart';

void main() {
  testWidgets('journal detail displays metrics and related publications', (
    tester,
  ) async {
    const journal = JournalInsight(
      name: 'Journal A',
      id: 'J1',
      publications: [_publication],
    );

    await tester.pumpWidget(
      const MaterialApp(home: JournalDetailScreen(journal: journal)),
    );

    expect(find.byKey(const Key('journal_detail_screen')), findsOneWidget);
    expect(find.text('Journal A'), findsNWidgets(2));
    expect(find.text('Related publications'), findsOneWidget);
    expect(find.text('Paper 1'), findsOneWidget);
  });

  testWidgets('keyword detail displays trend, journals, and authors', (
    tester,
  ) async {
    const keyword = KeywordInsight(
      name: 'AI',
      publications: [_publication],
      trend: [TrendData(year: 2024, publicationCount: 1)],
      growth: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(home: KeywordDetailScreen(keyword: keyword)),
    );

    expect(find.byKey(const Key('keyword_detail_screen')), findsOneWidget);
    expect(find.text('Publication trend over time'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Top contributing authors'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Related journals'), findsOneWidget);
    expect(find.text('Top contributing authors'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
  });
}

const _publication = Publication(
  id: 'https://openalex.org/W1',
  title: 'Paper 1',
  publicationYear: 2024,
  citationCount: 12,
  journalName: 'Journal A',
  journalId: 'J1',
  authors: ['Alice'],
  authorIdsByName: {'Alice': 'A1'},
  keywords: ['AI'],
  doi: 'https://doi.org/10.1000/test',
  abstractText: 'Test abstract',
);
