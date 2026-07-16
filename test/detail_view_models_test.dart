import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/models/journal_insight.dart';
import 'package:journal_trend_analysis/models/keyword_insight.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/models/trend_data.dart';
import 'package:journal_trend_analysis/viewmodels/journal_detail_view_model.dart';
import 'package:journal_trend_analysis/viewmodels/keyword_detail_view_model.dart';

void main() {
  const lowerCited = Publication(
    id: 'work-1',
    title: 'Lower cited',
    publicationYear: 2023,
    citationCount: 3,
    journalName: 'Journal A',
    authors: ['Author B'],
  );
  const higherCited = Publication(
    id: 'work-2',
    title: 'Higher cited',
    publicationYear: 2024,
    citationCount: 12,
    journalName: 'Journal B',
    authors: ['Author A'],
  );

  test('JournalDetailViewModel exposes metrics and citation ordering', () {
    final viewModel = JournalDetailViewModel(
      const JournalInsight(
        name: 'Journal',
        publications: [lowerCited, higherCited],
      ),
    );

    expect(viewModel.publicationCount, 2);
    expect(viewModel.totalCitations, 15);
    expect(viewModel.averageCitations, 7.5);
    expect(viewModel.publications.first, higherCited);
  });

  test('KeywordDetailViewModel derives rankings outside the view', () {
    final viewModel = KeywordDetailViewModel(
      const KeywordInsight(
        name: 'AI',
        publications: [lowerCited, higherCited],
        trend: [TrendData(year: 2024, publicationCount: 1)],
        growth: 1,
      ),
    );

    expect(viewModel.frequency, 2);
    expect(viewModel.totalCitations, 15);
    expect(viewModel.publications.first, higherCited);
    expect(viewModel.journals.first.name, 'Journal A');
    expect(viewModel.authors.map((item) => item.name), [
      'Author A',
      'Author B',
    ]);
  });
}
