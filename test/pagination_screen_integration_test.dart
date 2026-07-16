import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/models/openalex_search_state.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/repositories/openalex_repository.dart';
import 'package:journal_trend_analysis/screens/dashboard_screen.dart';
import 'package:journal_trend_analysis/screens/journals_screen.dart';
import 'package:journal_trend_analysis/viewmodels/journals_view_model.dart';
import 'package:journal_trend_analysis/viewmodels/research_tab_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Dashboard wires the default page size and Load more action', (
    tester,
  ) async {
    final repository = _ScreenPagingRepository(
      const OpenAlexSearchState(
        status: OpenAlexSearchStatus.success,
        publications: [_publication],
        totalCount: 2,
        nextCursor: 'cursor-2',
      ),
    );
    final viewModel = ResearchTabViewModel(
      initialTopic: 'AI',
      repository: repository,
    );
    var notificationTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ResearchTabViewModel>.value(
          value: viewModel,
          child: Scaffold(
            body: DashboardScreen(
              onOpenNotifications: () => notificationTaps += 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(repository.lastPerPage, 100);
    expect(find.text('Loaded 1 of 2 matching works'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openalex_load_more_button')));
    await tester.pump();
    expect(repository.loadMoreCalls, 1);

    await tester.tap(find.byKey(const Key('openalex_auto_load_button')));
    await tester.pump();
    expect(repository.autoLoadCalls, 1);

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    final searchField = tester.widget<TextField>(
      find.byKey(const Key('home_topic_search_field')),
    );
    expect(searchField.focusNode?.hasFocus, isTrue);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pump();
    expect(notificationTaps, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    viewModel.dispose();
  });

  testWidgets('Journals keeps loaded data visible and wires Retry', (
    tester,
  ) async {
    final repository = _ScreenPagingRepository(
      const OpenAlexSearchState(
        status: OpenAlexSearchStatus.success,
        publications: [_publication],
        totalCount: 2,
        nextCursor: 'cursor-2',
        loadMoreErrorMessage: 'Network unavailable',
      ),
    );
    final viewModel = JournalsViewModel(repository: repository);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<JournalsViewModel>.value(
          value: viewModel,
          child: const Scaffold(body: JournalsScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Journal A'), findsWidgets);
    expect(find.text('Network unavailable'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('openalex_load_more_retry')).hitTestable(),
    );
    await tester.pump();
    expect(repository.loadMoreCalls, 1);
    expect(repository.state.value.publications, [_publication]);

    await tester.pumpWidget(const SizedBox.shrink());
    viewModel.dispose();
  });
}

class _ScreenPagingRepository extends OpenAlexRepository {
  _ScreenPagingRepository(this.searchState);

  final OpenAlexSearchState searchState;
  int loadMoreCalls = 0;
  int autoLoadCalls = 0;
  int cancelAutoLoadCalls = 0;
  int? lastPerPage;

  @override
  Future<List<Publication>> searchTopic(
    String keyword, {
    int perPage = OpenAlexRepository.defaultPageSize,
  }) async {
    lastPerPage = perPage;
    state.value = searchState;
    return searchState.publications;
  }

  @override
  Future<List<Publication>> loadMore() async {
    loadMoreCalls += 1;
    return state.value.publications;
  }

  @override
  Future<List<Publication>> loadUpToLimit() async {
    autoLoadCalls += 1;
    return state.value.publications;
  }

  @override
  void cancelLoadUpToLimit() {
    cancelAutoLoadCalls += 1;
  }
}

const _publication = Publication(
  id: 'W1',
  title: 'Paper 1',
  publicationYear: 2024,
  citationCount: 12,
  journalName: 'Journal A',
  journalId: 'S1',
  authors: ['Alice'],
  keywords: ['AI'],
);
