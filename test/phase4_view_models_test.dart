import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/models/openalex_search_state.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/repositories/openalex_repository.dart';
import 'package:journal_trend_analysis/viewmodels/journals_view_model.dart';
import 'package:journal_trend_analysis/viewmodels/keywords_view_model.dart';

void main() {
  test(
    'journals are ranked with publication and citation statistics',
    () async {
      final repository = _PublicationRepository(_publications);
      final viewModel = JournalsViewModel(repository: repository);

      await viewModel.loadInitial();

      expect(viewModel.pageSize, 100);
      expect(viewModel.journals.map((item) => item.name), [
        'Journal A',
        'Journal B',
      ]);
      expect(viewModel.journals.first.publicationCount, 2);
      expect(viewModel.journals.first.totalCitations, 30);
      expect(viewModel.journals.first.averageCitations, 15);
      expect(viewModel.totalCitations, 35);

      viewModel.dispose();
    },
  );

  test('keywords expose frequency, trend, and growth rankings', () async {
    final repository = _PublicationRepository(_publications);
    final viewModel = KeywordsViewModel(repository: repository);

    await viewModel.loadInitial();

    final ai = viewModel.keywords.firstWhere((item) => item.name == 'AI');
    expect(ai.frequency, 3);
    expect(ai.totalCitations, 35);
    expect(ai.trend.map((item) => item.year), [2023, 2024]);
    expect(ai.growth, 1);
    expect(viewModel.trendingKeywords.first.name, 'AI');

    viewModel.dispose();
  });

  test('journal and keyword aggregations update after load more', () async {
    const nextPage = [
      Publication(
        id: 'W5',
        title: 'Paper 5',
        publicationYear: 2025,
        citationCount: 50,
        journalName: 'Journal C',
        authors: ['Carol'],
        keywords: ['Quantum'],
      ),
    ];
    final journalRepository = _PublicationRepository(
      _publications,
      nextPage: nextPage,
    );
    final keywordRepository = _PublicationRepository(
      _publications,
      nextPage: nextPage,
    );
    final journals = JournalsViewModel(repository: journalRepository);
    final keywords = KeywordsViewModel(repository: keywordRepository);

    await journals.loadInitial();
    expect(
      journals.journals.map((item) => item.name),
      isNot(contains('Journal C')),
    );
    await journals.loadMore();
    expect(journals.journals.map((item) => item.name), contains('Journal C'));
    expect(journals.totalCitations, 85);

    await keywords.loadInitial();
    await keywords.loadMore();
    expect(keywords.keywords.map((item) => item.name), contains('Quantum'));

    journals.dispose();
    keywords.dispose();
  });
}

class _PublicationRepository extends OpenAlexRepository {
  _PublicationRepository(this.publications, {this.nextPage = const []});

  final List<Publication> publications;
  final List<Publication> nextPage;

  @override
  Future<List<Publication>> searchTopic(
    String keyword, {
    int perPage = 20,
  }) async {
    state.value = OpenAlexSearchState(
      status: OpenAlexSearchStatus.success,
      publications: publications,
    );
    return publications;
  }

  @override
  Future<List<Publication>> loadMore() async {
    final merged = [...state.value.publications, ...nextPage];
    state.value = OpenAlexSearchState(
      status: OpenAlexSearchStatus.success,
      publications: merged,
      totalCount: merged.length,
    );
    return merged;
  }
}

const _publications = <Publication>[
  Publication(
    id: 'W1',
    title: 'Paper 1',
    publicationYear: 2023,
    citationCount: 10,
    journalName: 'Journal A',
    journalId: 'J1',
    authors: ['Alice'],
    authorIdsByName: {'Alice': 'A1'},
    keywords: ['AI', 'ML'],
  ),
  Publication(
    id: 'W2',
    title: 'Paper 2',
    publicationYear: 2024,
    citationCount: 20,
    journalName: 'Journal A',
    journalId: 'J1',
    authors: ['Alice', 'Bob'],
    authorIdsByName: {'Alice': 'A1', 'Bob': 'A2'},
    keywords: ['AI'],
  ),
  Publication(
    id: 'W3',
    title: 'Paper 3',
    publicationYear: 2024,
    citationCount: 5,
    journalName: 'Journal B',
    journalId: 'J2',
    authors: ['Bob'],
    authorIdsByName: {'Bob': 'A2'},
    keywords: ['AI', 'Data'],
  ),
  Publication(
    id: 'W4',
    title: 'Unknown venue',
    publicationYear: 2024,
    citationCount: 0,
    journalName: 'Unknown Journal',
    authors: [],
  ),
];
