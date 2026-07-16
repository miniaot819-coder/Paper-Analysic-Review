import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/models/openalex_page.dart';
import 'package:journal_trend_analysis/models/openalex_search_state.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/repositories/openalex_repository.dart';
import 'package:journal_trend_analysis/services/openalex_service.dart';

void main() {
  test('first page exposes publications, total count, and cursor', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(service: service);

    final request = repository.searchTopic('ai');
    expect(repository.state.value.status, OpenAlexSearchStatus.loading);
    service.complete(
      'ai',
      '*',
      _page([_publication('W1')], totalCount: 250, nextCursor: 'c2'),
    );
    final publications = await request;

    expect(publications.map((item) => item.id), ['W1']);
    expect(repository.state.value.status, OpenAlexSearchStatus.success);
    expect(repository.state.value.loadedCount, 1);
    expect(repository.state.value.totalCount, 250);
    expect(repository.state.value.nextCursor, 'c2');
    expect(repository.state.value.hasMore, isTrue);

    repository.dispose();
  });

  test('loadMore appends in order and deduplicates non-empty ids', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(service: service);

    final initial = repository.searchTopic('ai');
    service.complete(
      'ai',
      '*',
      _page(
        [_publication('W1'), _publication('')],
        totalCount: 5,
        nextCursor: 'c2',
      ),
    );
    await initial;

    final next = repository.loadMore();
    expect(repository.state.value.isLoadingMore, isTrue);
    service.complete(
      'ai',
      'c2',
      _page(
        [_publication('W1'), _publication('W2'), _publication('')],
        totalCount: 5,
        nextCursor: null,
      ),
    );
    await next;

    expect(repository.state.value.publications.map((item) => item.id), [
      'W1',
      '',
      'W2',
      '',
    ]);
    expect(repository.state.value.isLoadingMore, isFalse);
    expect(repository.state.value.hasMore, isFalse);

    repository.dispose();
  });

  test(
    'load-more failure preserves data and retry uses the same cursor',
    () async {
      final service = _ControlledOpenAlexService();
      final repository = OpenAlexRepository(service: service);

      final initial = repository.searchTopic('ai');
      service.complete(
        'ai',
        '*',
        _page([_publication('W1')], totalCount: 2, nextCursor: 'c2'),
      );
      await initial;

      final failedLoad = repository.loadMore();
      service.fail('ai', 'c2', const OpenAlexException('Temporary failure'));
      await failedLoad;

      expect(repository.state.value.status, OpenAlexSearchStatus.success);
      expect(repository.state.value.publications.map((item) => item.id), [
        'W1',
      ]);
      expect(repository.state.value.nextCursor, 'c2');
      expect(repository.state.value.loadMoreErrorMessage, 'Temporary failure');

      final retry = repository.loadMore();
      expect(repository.state.value.loadMoreErrorMessage, isNull);
      service.complete(
        'ai',
        'c2',
        _page([_publication('W2')], totalCount: 2, nextCursor: null),
        requestIndex: 1,
      );
      await retry;

      expect(repository.state.value.publications.map((item) => item.id), [
        'W1',
        'W2',
      ]);
      expect(repository.state.value.loadMoreErrorMessage, isNull);

      repository.dispose();
    },
  );

  test('duplicate loadMore calls create only one request', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(service: service);

    final initial = repository.searchTopic('ai');
    service.complete(
      'ai',
      '*',
      _page([_publication('W1')], totalCount: 2, nextCursor: 'c2'),
    );
    await initial;

    final first = repository.loadMore();
    final duplicate = repository.loadMore();
    expect(service.callCount('ai', 'c2'), 1);
    service.complete(
      'ai',
      'c2',
      _page([_publication('W2')], totalCount: 2, nextCursor: null),
    );

    await Future.wait([first, duplicate]);
    expect(repository.state.value.publications, hasLength(2));

    repository.dispose();
  });

  test(
    'automatic loading fetches cursor pages sequentially up to cap',
    () async {
      final service = _ControlledOpenAlexService();
      final repository = OpenAlexRepository(
        service: service,
        maximumLoadedWorks: 4,
      );

      final initial = repository.searchTopic('ai', perPage: 2);
      service.complete(
        'ai',
        '*',
        _page([_publication('W1')], totalCount: 8, nextCursor: 'c2'),
      );
      await initial;

      final automaticLoad = repository.loadUpToLimit();
      expect(repository.state.value.isAutoLoading, isTrue);
      expect(service.callCount('ai', 'c2'), 1);
      service.complete(
        'ai',
        'c2',
        _page(
          [_publication('W2'), _publication('W3')],
          totalCount: 8,
          nextCursor: 'c3',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      for (
        var attempt = 0;
        attempt < 10 && service.callCount('ai', 'c3') == 0;
        attempt += 1
      ) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(repository.state.value.loadedCount, 3);
      expect(repository.state.value.isAutoLoading, isTrue);
      expect(service.callCount('ai', 'c3'), 1);
      service.complete(
        'ai',
        'c3',
        _page(
          [_publication('W4'), _publication('W5')],
          totalCount: 8,
          nextCursor: 'c4',
        ),
      );
      await automaticLoad;

      expect(repository.state.value.publications.map((item) => item.id), [
        'W1',
        'W2',
        'W3',
        'W4',
      ]);
      expect(repository.state.value.reachedResultLimit, isTrue);
      expect(repository.state.value.isAutoLoading, isFalse);
      expect(repository.state.value.hasMore, isFalse);

      repository.dispose();
    },
  );

  test(
    'automatic loading can be cancelled without appending in-flight page',
    () async {
      final service = _ControlledOpenAlexService();
      final repository = OpenAlexRepository(service: service);

      final initial = repository.searchTopic('ai');
      service.complete(
        'ai',
        '*',
        _page([_publication('W1')], totalCount: 300, nextCursor: 'c2'),
      );
      await initial;

      final automaticLoad = repository.loadUpToLimit();
      repository.cancelLoadUpToLimit();
      expect(repository.state.value.isAutoLoadCancellationPending, isTrue);
      service.complete(
        'ai',
        'c2',
        _page([_publication('W2')], totalCount: 300, nextCursor: 'c3'),
      );
      await automaticLoad;

      expect(repository.state.value.publications.map((item) => item.id), [
        'W1',
      ]);
      expect(repository.state.value.nextCursor, 'c2');
      expect(repository.state.value.isLoadingMore, isFalse);
      expect(repository.state.value.isAutoLoading, isFalse);
      expect(repository.state.value.isAutoLoadCancellationPending, isFalse);

      repository.dispose();
    },
  );

  test('new search supersedes an in-flight automatic load', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(service: service);

    final initial = repository.searchTopic('first');
    service.complete(
      'first',
      '*',
      _page([_publication('F1')], totalCount: 200, nextCursor: 'first-c2'),
    );
    await initial;

    final staleAutomaticLoad = repository.loadUpToLimit();
    final replacementSearch = repository.searchTopic('second');
    service.complete(
      'second',
      '*',
      _page([_publication('S1')], totalCount: 1, nextCursor: null),
    );
    await replacementSearch;
    service.complete(
      'first',
      'first-c2',
      _page([_publication('F2')], totalCount: 200, nextCursor: 'first-c3'),
    );
    await staleAutomaticLoad;

    expect(repository.state.value.publications.single.id, 'S1');
    expect(repository.state.value.isAutoLoading, isFalse);

    repository.dispose();
  });

  test(
    'automatic load failure preserves data and can resume from cursor',
    () async {
      final service = _ControlledOpenAlexService();
      final repository = OpenAlexRepository(service: service);

      final initial = repository.searchTopic('ai');
      service.complete(
        'ai',
        '*',
        _page([_publication('W1')], totalCount: 2, nextCursor: 'c2'),
      );
      await initial;

      final failedLoad = repository.loadUpToLimit();
      service.fail('ai', 'c2', const OpenAlexException('Temporary failure'));
      await failedLoad;

      expect(repository.state.value.publications.single.id, 'W1');
      expect(repository.state.value.nextCursor, 'c2');
      expect(repository.state.value.autoLoadFailed, isTrue);
      expect(repository.state.value.loadMoreErrorMessage, 'Temporary failure');

      final resumedLoad = repository.loadUpToLimit();
      service.complete(
        'ai',
        'c2',
        _page([_publication('W2')], totalCount: 2, nextCursor: null),
        requestIndex: 1,
      );
      await resumedLoad;

      expect(repository.state.value.publications.map((item) => item.id), [
        'W1',
        'W2',
      ]);
      expect(repository.state.value.autoLoadFailed, isFalse);
      expect(repository.state.value.loadMoreErrorMessage, isNull);

      repository.dispose();
    },
  );

  test(
    'repeated cursor stops pagination and never appends a looped page',
    () async {
      final service = _ControlledOpenAlexService();
      final repository = OpenAlexRepository(service: service);

      final initial = repository.searchTopic('ai');
      service.complete(
        'ai',
        '*',
        _page([_publication('W1')], totalCount: 2, nextCursor: 'c2'),
      );
      await initial;

      final next = repository.loadMore();
      service.complete(
        'ai',
        'c2',
        _page([_publication('W2')], totalCount: 2, nextCursor: 'c2'),
      );
      await next;

      expect(repository.state.value.publications.single.id, 'W1');
      expect(repository.state.value.nextCursor, isNull);
      expect(repository.state.value.hasMore, isFalse);
      expect(
        repository.state.value.loadMoreErrorMessage,
        contains('same cursor twice'),
      );

      await repository.loadMore();
      expect(service.callCount('ai', 'c2'), 1);

      repository.dispose();
    },
  );

  test('valid next cursor remains usable when total count decreases', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(service: service);

    final initial = repository.searchTopic('ai');
    service.complete(
      'ai',
      '*',
      _page([_publication('W1')], totalCount: 10, nextCursor: 'c2'),
    );
    await initial;

    final next = repository.loadMore();
    service.complete(
      'ai',
      'c2',
      _page([_publication('W2')], totalCount: 1, nextCursor: 'c3'),
    );
    await next;

    expect(repository.state.value.totalCount, 10);
    expect(repository.state.value.nextCursor, 'c3');
    expect(repository.state.value.hasMore, isTrue);

    repository.dispose();
  });

  test('loaded publications never exceed the configured safety cap', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(
      service: service,
      maximumLoadedWorks: 3,
    );

    final initial = repository.searchTopic('ai');
    service.complete(
      'ai',
      '*',
      _page(
        [_publication('W1'), _publication('W2')],
        totalCount: 5,
        nextCursor: 'c2',
      ),
    );
    await initial;

    final next = repository.loadMore();
    service.complete(
      'ai',
      'c2',
      _page(
        [_publication('W3'), _publication('W4'), _publication('W5')],
        totalCount: 5,
        nextCursor: 'c3',
      ),
    );
    await next;

    expect(repository.state.value.publications.map((item) => item.id), [
      'W1',
      'W2',
      'W3',
    ]);
    expect(repository.state.value.reachedResultLimit, isTrue);
    expect(repository.state.value.nextCursor, isNull);
    expect(repository.state.value.hasMore, isFalse);

    repository.dispose();
  });

  test(
    'exactly reaching the complete result count is not a cap warning',
    () async {
      final service = _ControlledOpenAlexService();
      final repository = OpenAlexRepository(
        service: service,
        maximumLoadedWorks: 3,
      );

      final initial = repository.searchTopic('ai');
      service.complete(
        'ai',
        '*',
        _page(
          [_publication('W1'), _publication('W2'), _publication('W3')],
          totalCount: 3,
          nextCursor: 'terminal-probe',
        ),
      );
      await initial;

      expect(repository.state.value.publications, hasLength(3));
      expect(repository.state.value.nextCursor, isNull);
      expect(repository.state.value.reachedResultLimit, isFalse);
      expect(repository.state.value.hasMore, isFalse);

      repository.dispose();
    },
  );

  test('first page is deduplicated and truncated at the safety cap', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(
      service: service,
      maximumLoadedWorks: 2,
    );

    final initial = repository.searchTopic('ai');
    service.complete(
      'ai',
      '*',
      _page(
        [
          _publication('W1'),
          _publication('W1'),
          _publication('W2'),
          _publication('W3'),
        ],
        totalCount: 4,
        nextCursor: 'c2',
      ),
    );
    await initial;

    expect(repository.state.value.publications.map((item) => item.id), [
      'W1',
      'W2',
    ]);
    expect(repository.state.value.reachedResultLimit, isTrue);
    expect(repository.state.value.nextCursor, isNull);

    repository.dispose();
  });

  test('new search ignores an older search and in-flight load-more', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(service: service);

    final staleSearch = repository.searchTopic('first');
    final currentSearch = repository.searchTopic('second');
    service.complete(
      'second',
      '*',
      _page([_publication('S1')], totalCount: 2, nextCursor: 'second-c2'),
    );
    await currentSearch;
    service.fail('first', '*', const OpenAlexException('stale failure'));
    await staleSearch;
    expect(repository.state.value.publications.single.id, 'S1');

    final staleLoadMore = repository.loadMore();
    final replacementSearch = repository.searchTopic('third');
    service.complete(
      'third',
      '*',
      _page([_publication('T1')], totalCount: 1, nextCursor: null),
    );
    await replacementSearch;
    service.complete(
      'second',
      'second-c2',
      _page([_publication('S2')], totalCount: 2, nextCursor: null),
    );
    await staleLoadMore;

    expect(repository.state.value.publications.single.id, 'T1');

    repository.dispose();
  });

  test(
    'publication detail lookup does not overwrite topic pagination state',
    () async {
      final service = _ControlledOpenAlexService();
      final repository = OpenAlexRepository(service: service);

      final initial = repository.searchTopic('ai');
      service.complete(
        'ai',
        '*',
        _page([_publication('W1')], totalCount: 2, nextCursor: 'c2'),
      );
      await initial;

      final detailRequest = repository.getPublicationDetail('W-detail');
      service.completeDetail(_publication('W-detail'));
      final detail = await detailRequest;

      expect(detail?.id, 'W-detail');
      expect(repository.state.value.publications.single.id, 'W1');
      expect(repository.state.value.nextCursor, 'c2');

      repository.dispose();
    },
  );

  test('completing a request after dispose does not update state', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(service: service);

    final request = repository.searchTopic('pending');
    repository.dispose();
    service.complete(
      'pending',
      '*',
      _page(const [], totalCount: 0, nextCursor: null),
    );

    await expectLater(request, completes);
  });

  test('initial service failure is exposed as recoverable failure', () async {
    final service = _ControlledOpenAlexService();
    final repository = OpenAlexRepository(service: service);

    final request = repository.searchTopic('offline');
    service.fail(
      'offline',
      '*',
      const OpenAlexException('Network unavailable'),
    );
    final publications = await request;

    expect(publications, isEmpty);
    expect(repository.state.value.status, OpenAlexSearchStatus.failure);
    expect(repository.state.value.errorMessage, 'Network unavailable');

    repository.dispose();
  });

  test('author and journal lookup failures fall back to empty lists', () async {
    final repository = OpenAlexRepository(
      service: _FailingLookupOpenAlexService(),
    );

    expect(await repository.getWorksByAuthor('A1'), isEmpty);
    expect(await repository.getWorksByJournal('S1'), isEmpty);

    repository.dispose();
  });
}

class _FailingLookupOpenAlexService extends OpenAlexService {
  @override
  Future<List<Publication>> getWorksByAuthor(
    String authorId, {
    int perPage = 20,
  }) async {
    throw const OpenAlexException('Author lookup failed');
  }

  @override
  Future<List<Publication>> getWorksByJournal(
    String journalId, {
    int perPage = 20,
  }) async {
    throw const OpenAlexException('Journal lookup failed');
  }
}

class _ControlledOpenAlexService extends OpenAlexService {
  final Map<String, List<Completer<OpenAlexPage<Publication>>>> _requests = {};
  Completer<Publication>? _detailRequest;

  @override
  Future<OpenAlexPage<Publication>> searchTopicPage(
    String keyword, {
    int perPage = OpenAlexService.maxPerPage,
    String cursor = '*',
  }) {
    final completer = Completer<OpenAlexPage<Publication>>();
    _requests.putIfAbsent(_key(keyword, cursor), () => []).add(completer);
    return completer.future;
  }

  int callCount(String keyword, String cursor) {
    return _requests[_key(keyword, cursor)]?.length ?? 0;
  }

  @override
  Future<Publication> getPublicationDetail(String id) {
    _detailRequest = Completer<Publication>();
    return _detailRequest!.future;
  }

  void completeDetail(Publication publication) {
    _detailRequest!.complete(publication);
  }

  void complete(
    String keyword,
    String cursor,
    OpenAlexPage<Publication> page, {
    int requestIndex = 0,
  }) {
    _requests[_key(keyword, cursor)]![requestIndex].complete(page);
  }

  void fail(
    String keyword,
    String cursor,
    Object error, {
    int requestIndex = 0,
  }) {
    _requests[_key(keyword, cursor)]![requestIndex].completeError(error);
  }

  String _key(String keyword, String cursor) => '$keyword::$cursor';
}

OpenAlexPage<Publication> _page(
  List<Publication> publications, {
  required int totalCount,
  required String? nextCursor,
}) {
  return OpenAlexPage<Publication>(
    items: publications,
    totalCount: totalCount,
    nextCursor: nextCursor,
  );
}

Publication _publication(String id) {
  return Publication(
    id: id,
    title: id.isEmpty ? 'Untitled' : 'Paper $id',
    publicationYear: 2026,
    citationCount: 1,
    journalName: 'Journal',
    authors: const ['Author'],
  );
}
