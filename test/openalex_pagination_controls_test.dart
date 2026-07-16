import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/widgets/openalex_pagination_controls.dart';

void main() {
  testWidgets('shows loaded count and invokes Load more', (tester) async {
    var loadMoreCalls = 0;
    await tester.pumpWidget(
      _app(
        OpenAlexPaginationControls(
          loadedCount: 100,
          totalCount: 450,
          hasMore: true,
          isLoadingMore: false,
          reachedResultLimit: false,
          maximumLoadedWorks: 1000,
          pageSize: 100,
          onLoadMore: () => loadMoreCalls += 1,
          onLoadUpToLimit: () {},
          onCancelAutoLoad: () {},
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Loaded 100 of 450 matching works'), findsOneWidget);
    await tester.tap(find.byKey(const Key('openalex_load_more_button')));
    await tester.pump();
    expect(loadMoreCalls, 1);
  });

  testWidgets('keeps a compact progress state while loading more', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        OpenAlexPaginationControls(
          loadedCount: 100,
          totalCount: 450,
          hasMore: true,
          isLoadingMore: true,
          reachedResultLimit: false,
          maximumLoadedWorks: 1000,
          pageSize: 100,
          onLoadMore: () {},
          onLoadUpToLimit: () {},
          onCancelAutoLoad: () {},
          onRetry: () {},
        ),
      ),
    );

    expect(
      find.byKey(const Key('openalex_load_more_progress')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('openalex_load_more_button')), findsNothing);
  });

  testWidgets('offers one-tap automatic loading and a safe cancel action', (
    tester,
  ) async {
    var autoLoadCalls = 0;
    var cancelCalls = 0;
    await tester.pumpWidget(
      _app(
        OpenAlexPaginationControls(
          loadedCount: 100,
          totalCount: 2450,
          hasMore: true,
          isLoadingMore: false,
          reachedResultLimit: false,
          maximumLoadedWorks: 1000,
          pageSize: 100,
          onLoadMore: () {},
          onLoadUpToLimit: () => autoLoadCalls += 1,
          onCancelAutoLoad: () => cancelCalls += 1,
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Load next 100'), findsOneWidget);
    expect(find.text('Load up to 1,000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('openalex_auto_load_button')));
    expect(autoLoadCalls, 1);

    await tester.pumpWidget(
      _app(
        OpenAlexPaginationControls(
          loadedCount: 300,
          totalCount: 2450,
          hasMore: true,
          isLoadingMore: true,
          isAutoLoading: true,
          reachedResultLimit: false,
          maximumLoadedWorks: 1000,
          pageSize: 100,
          onLoadMore: () {},
          onLoadUpToLimit: () {},
          onCancelAutoLoad: () => cancelCalls += 1,
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Loading 300 of up to 1,000 works...'), findsOneWidget);
    await tester.tap(find.byKey(const Key('openalex_auto_load_cancel')));
    expect(cancelCalls, 1);
  });

  testWidgets('shows a retry action after a load-more failure', (tester) async {
    var retryCalls = 0;
    await tester.pumpWidget(
      _app(
        OpenAlexPaginationControls(
          loadedCount: 100,
          totalCount: 450,
          hasMore: true,
          isLoadingMore: false,
          reachedResultLimit: false,
          maximumLoadedWorks: 1000,
          pageSize: 100,
          loadMoreErrorMessage: 'Temporary OpenAlex failure',
          onLoadMore: () {},
          onLoadUpToLimit: () {},
          onCancelAutoLoad: () {},
          onRetry: () => retryCalls += 1,
        ),
      ),
    );

    expect(find.text('Temporary OpenAlex failure'), findsOneWidget);
    await tester.tap(find.byKey(const Key('openalex_load_more_retry')));
    await tester.pump();
    expect(retryCalls, 1);
  });

  testWidgets('does not offer retry after terminal pagination failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        OpenAlexPaginationControls(
          loadedCount: 100,
          totalCount: 450,
          hasMore: false,
          isLoadingMore: false,
          reachedResultLimit: false,
          maximumLoadedWorks: 1000,
          pageSize: 100,
          loadMoreErrorMessage: 'Pagination stopped safely',
          onLoadMore: () {},
          onLoadUpToLimit: () {},
          onCancelAutoLoad: () {},
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Pagination stopped safely'), findsOneWidget);
    expect(find.byKey(const Key('openalex_load_more_retry')), findsNothing);
  });

  testWidgets('shows the safety-cap notice without Load more', (tester) async {
    await tester.pumpWidget(
      _app(
        OpenAlexPaginationControls(
          loadedCount: 1000,
          totalCount: 48219,
          hasMore: false,
          isLoadingMore: false,
          reachedResultLimit: true,
          maximumLoadedWorks: 1000,
          pageSize: 100,
          onLoadMore: () {},
          onLoadUpToLimit: () {},
          onCancelAutoLoad: () {},
          onRetry: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('openalex_cap_notice')), findsOneWidget);
    expect(find.text('Loaded 1,000 of 48,219 matching works'), findsOneWidget);
    expect(
      find.textContaining('Reached the 1,000-work app limit.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('openalex_load_more_button')), findsNothing);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}
