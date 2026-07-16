import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/models/openalex_search_state.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/repositories/openalex_repository.dart';
import 'package:journal_trend_analysis/viewmodels/research_tab_view_model.dart';

void main() {
  test('tab view models keep topic and search history independent', () async {
    final homeRepository = _FakeOpenAlexRepository();
    final journalsRepository = _FakeOpenAlexRepository();
    final home = ResearchTabViewModel(
      initialTopic: 'AI',
      repository: homeRepository,
    );
    final journals = ResearchTabViewModel(
      initialTopic: 'Medicine',
      repository: journalsRepository,
    );

    await home.search('Machine Learning', perPage: 0);

    expect(home.topic, 'Machine Learning');
    expect(home.pageSize, 100);
    expect(home.recentSearches, ['Machine Learning']);
    expect(homeRepository.lastTopic, 'Machine Learning');
    expect(journals.topic, 'Medicine');
    expect(journals.recentSearches, isEmpty);
    expect(journalsRepository.searchCount, 0);

    home.dispose();
    journals.dispose();
  });

  test('initial topic is loaded only once', () async {
    final repository = _FakeOpenAlexRepository();
    final viewModel = ResearchTabViewModel(
      initialTopic: 'Cybersecurity',
      repository: repository,
    );

    await viewModel.loadInitial();
    await viewModel.loadInitial();

    expect(repository.searchCount, 1);
    expect(repository.lastTopic, 'Cybersecurity');
    expect(viewModel.hasLoaded, isTrue);

    viewModel.dispose();
  });

  test('OpenAlex page size is clamped to 100 works', () async {
    final repository = _FakeOpenAlexRepository();
    final viewModel = ResearchTabViewModel(
      initialTopic: 'AI',
      repository: repository,
    );

    await viewModel.search('AI safety', perPage: 999);

    expect(viewModel.pageSize, 100);
    expect(repository.lastPerPage, 100);
    expect(viewModel.maximumLoadedWorks, 1000);

    viewModel.dispose();
  });

  test('loadMore and retry delegate to the tab repository', () async {
    final repository = _FakeOpenAlexRepository();
    final viewModel = ResearchTabViewModel(
      initialTopic: 'AI',
      repository: repository,
    );

    await viewModel.loadMore();
    await viewModel.retryLoadMore();

    expect(repository.loadMoreCount, 2);

    viewModel.dispose();
  });

  test(
    'automatic loading, cancel and failed retry delegate correctly',
    () async {
      final repository = _FakeOpenAlexRepository();
      final viewModel = ResearchTabViewModel(
        initialTopic: 'AI',
        repository: repository,
      );

      await viewModel.loadUpToLimit();
      viewModel.cancelLoadUpToLimit();
      repository.state.value = const OpenAlexSearchState(
        status: OpenAlexSearchStatus.success,
        autoLoadFailed: true,
      );
      await viewModel.retryLoadMore();

      expect(repository.autoLoadCount, 2);
      expect(repository.cancelAutoLoadCount, 1);
      expect(repository.loadMoreCount, 0);

      viewModel.dispose();
    },
  );
}

class _FakeOpenAlexRepository extends OpenAlexRepository {
  int searchCount = 0;
  int loadMoreCount = 0;
  int autoLoadCount = 0;
  int cancelAutoLoadCount = 0;
  String? lastTopic;
  int? lastPerPage;

  @override
  Future<List<Publication>> searchTopic(
    String keyword, {
    int perPage = 20,
  }) async {
    searchCount += 1;
    lastTopic = keyword;
    lastPerPage = perPage;
    state.value = const OpenAlexSearchState(
      status: OpenAlexSearchStatus.success,
    );
    return const [];
  }

  @override
  Future<List<Publication>> loadMore() async {
    loadMoreCount += 1;
    return state.value.publications;
  }

  @override
  Future<List<Publication>> loadUpToLimit() async {
    autoLoadCount += 1;
    return state.value.publications;
  }

  @override
  void cancelLoadUpToLimit() {
    cancelAutoLoadCount += 1;
  }
}
