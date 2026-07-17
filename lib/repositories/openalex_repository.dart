import 'package:flutter/foundation.dart';

import '../models/openalex_search_state.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';

class OpenAlexRepository {
  OpenAlexRepository({
    OpenAlexService? service,
    this.maximumLoadedWorks = defaultMaximumLoadedWorks,
  }) : assert(maximumLoadedWorks > 0),
       _ownsService = service == null,
       _service = service ?? OpenAlexService();

  static const int defaultPageSize = 100;
  static const int defaultMaximumLoadedWorks = 1000;

  final OpenAlexService _service;
  final bool _ownsService;
  final int maximumLoadedWorks;

  int _stateRequestId = 0;
  int _autoLoadOperationId = 0;
  bool _isDisposed = false;
  String? _activeKeyword;
  int _activePerPage = defaultPageSize;

  final ValueNotifier<OpenAlexSearchState> state =
      ValueNotifier<OpenAlexSearchState>(const OpenAlexSearchState.idle());

  Future<List<Publication>> searchTopic(
    String keyword, {
    int perPage = defaultPageSize,
  }) async {
    final requestId = _beginStateRequest();
    if (_isDisposed) return const [];

    _activeKeyword = keyword.trim();
    _activePerPage = perPage.clamp(1, OpenAlexService.maxPerPage);

    try {
      final page = await _service.searchTopicPage(
        _activeKeyword!,
        perPage: _activePerPage,
      );
      final publications = _appendUnique(const [], page.items);
      final reachedResultLimit = _reachedLimit(
        loadedCount: publications.length,
        totalCount: page.totalCount,
      );
      final hasCapacity = publications.length < maximumLoadedWorks;
      _setStateIfCurrent(
        requestId,
        OpenAlexSearchState(
          status: OpenAlexSearchStatus.success,
          publications: List<Publication>.unmodifiable(publications),
          totalCount: page.totalCount,
          nextCursor: publications.isEmpty || !hasCapacity
              ? null
              : page.nextCursor,
          reachedResultLimit: reachedResultLimit,
        ),
      );
      return publications;
    } on OpenAlexException catch (error) {
      _setStateIfCurrent(
        requestId,
        OpenAlexSearchState(
          status: OpenAlexSearchStatus.failure,
          errorMessage: error.message,
        ),
      );
      return const [];
    } catch (error) {
      _setStateIfCurrent(
        requestId,
        OpenAlexSearchState(
          status: OpenAlexSearchStatus.failure,
          errorMessage: 'Unexpected error: $error',
        ),
      );
      return const [];
    }
  }

  Future<List<Publication>> loadMore() async {
    final currentState = state.value;
    final keyword = _activeKeyword;
    if (_isDisposed ||
        keyword == null ||
        keyword.isEmpty ||
        !currentState.canLoadMore) {
      return currentState.publications;
    }

    final requestId = _stateRequestId;
    final cursor = currentState.nextCursor!;
    state.value = currentState.copyWith(
      isLoadingMore: true,
      isAutoLoading: false,
      isAutoLoadCancellationPending: false,
      autoLoadFailed: false,
      loadMoreErrorMessage: null,
    );

    try {
      final page = await _service.searchTopicPage(
        keyword,
        perPage: _activePerPage,
        cursor: cursor,
      );
      if (!_isCurrent(requestId)) return state.value.publications;
      if (page.nextCursor == cursor) {
        state.value = state.value.copyWith(
          nextCursor: null,
          isLoadingMore: false,
          loadMoreErrorMessage:
              'OpenAlex stopped pagination because it returned the same '
              'cursor twice. Run the search again to restart safely.',
        );
        return state.value.publications;
      }

      final publications = _appendUnique(state.value.publications, page.items);
      final totalCount = page.totalCount > state.value.totalCount
          ? page.totalCount
          : state.value.totalCount;
      final reachedResultLimit = _reachedLimit(
        loadedCount: publications.length,
        totalCount: totalCount,
      );
      final hasCapacity = publications.length < maximumLoadedWorks;
      final hasUsableNextPage =
          page.nextCursor != null && hasCapacity && !reachedResultLimit;

      state.value = OpenAlexSearchState(
        status: OpenAlexSearchStatus.success,
        publications: List<Publication>.unmodifiable(publications),
        totalCount: totalCount < publications.length
            ? publications.length
            : totalCount,
        nextCursor: hasUsableNextPage ? page.nextCursor : null,
        reachedResultLimit: reachedResultLimit,
      );
      return publications;
    } on OpenAlexException catch (error) {
      _setLoadMoreFailureIfCurrent(requestId, error.message);
      return state.value.publications;
    } catch (error) {
      _setLoadMoreFailureIfCurrent(requestId, 'Unexpected error: $error');
      return state.value.publications;
    }
  }

  /// Fetches cursor pages sequentially until all available results are loaded
  /// or [maximumLoadedWorks] is reached.
  ///
  /// OpenAlex accepts at most 100 works per request, so this intentionally
  /// remains a sequence of bounded requests instead of one oversized call.
  Future<List<Publication>> loadUpToLimit() async {
    final currentState = state.value;
    final keyword = _activeKeyword;
    if (_isDisposed ||
        keyword == null ||
        keyword.isEmpty ||
        !currentState.canLoadMore) {
      return currentState.publications;
    }

    final requestId = _stateRequestId;
    final operationId = ++_autoLoadOperationId;
    final seenCursors = <String>{};
    final remainingCapacity = maximumLoadedWorks - currentState.loadedCount;
    final idealRemainingPages = (remainingCapacity / _activePerPage)
        .ceil()
        .clamp(1, 1000000);
    // Two extra requests tolerate a small amount of cross-page de-duplication
    // while guaranteeing that a malformed API response cannot loop forever.
    final maximumPageRequests = idealRemainingPages + 2;
    var pageRequests = 0;

    state.value = currentState.copyWith(
      isLoadingMore: true,
      isAutoLoading: true,
      isAutoLoadCancellationPending: false,
      autoLoadFailed: false,
      loadMoreErrorMessage: null,
    );

    while (_isCurrent(requestId)) {
      if (operationId != _autoLoadOperationId) {
        _finishAutoLoadCancellationIfCurrent(requestId);
        break;
      }

      final beforePage = state.value;
      final cursor = beforePage.nextCursor;
      if (!beforePage.hasMore || cursor == null || cursor.isEmpty) {
        _finishAutoLoadIfCurrent(requestId);
        break;
      }
      if (!seenCursors.add(cursor)) {
        _stopAtUnsafeCursorIfCurrent(requestId);
        break;
      }
      if (pageRequests >= maximumPageRequests) {
        _setLoadMoreFailureIfCurrent(
          requestId,
          'OpenAlex returned too few unique works across consecutive pages. '
          'Automatic loading stopped safely; retry or refine the topic.',
          autoLoadFailed: true,
        );
        break;
      }
      pageRequests += 1;

      try {
        final page = await _service.searchTopicPage(
          keyword,
          perPage: _activePerPage,
          cursor: cursor,
        );
        if (!_isCurrent(requestId)) return state.value.publications;
        if (operationId != _autoLoadOperationId) {
          _finishAutoLoadCancellationIfCurrent(requestId);
          break;
        }
        if (page.nextCursor == cursor ||
            (page.nextCursor != null &&
                seenCursors.contains(page.nextCursor))) {
          _stopAtUnsafeCursorIfCurrent(requestId);
          break;
        }

        final publications = _appendUnique(
          state.value.publications,
          page.items,
        );
        final totalCount = page.totalCount > state.value.totalCount
            ? page.totalCount
            : state.value.totalCount;
        final reachedResultLimit = _reachedLimit(
          loadedCount: publications.length,
          totalCount: totalCount,
        );
        final hasCapacity = publications.length < maximumLoadedWorks;
        final hasUsableNextPage =
            page.nextCursor != null && hasCapacity && !reachedResultLimit;

        state.value = OpenAlexSearchState(
          status: OpenAlexSearchStatus.success,
          publications: List<Publication>.unmodifiable(publications),
          totalCount: totalCount < publications.length
              ? publications.length
              : totalCount,
          nextCursor: hasUsableNextPage ? page.nextCursor : null,
          isLoadingMore: hasUsableNextPage,
          isAutoLoading: hasUsableNextPage,
          reachedResultLimit: reachedResultLimit,
        );
        if (!hasUsableNextPage) break;

        // Give the UI an opportunity to render progress and process Cancel
        // before the following cursor request begins.
        await Future<void>.delayed(Duration.zero);
      } on OpenAlexException catch (error) {
        if (operationId != _autoLoadOperationId) {
          _finishAutoLoadCancellationIfCurrent(requestId);
        } else {
          _setLoadMoreFailureIfCurrent(
            requestId,
            error.message,
            autoLoadFailed: true,
          );
        }
        break;
      } catch (error) {
        if (operationId != _autoLoadOperationId) {
          _finishAutoLoadCancellationIfCurrent(requestId);
        } else {
          _setLoadMoreFailureIfCurrent(
            requestId,
            'Unexpected error: $error',
            autoLoadFailed: true,
          );
        }
        break;
      }
    }

    return state.value.publications;
  }

  /// Requests a cooperative stop. The in-flight HTTP request is allowed to
  /// finish, but its page is discarded and no further cursor is requested.
  void cancelLoadUpToLimit() {
    if (_isDisposed ||
        !state.value.isAutoLoading ||
        state.value.isAutoLoadCancellationPending) {
      return;
    }
    _autoLoadOperationId += 1;
    state.value = state.value.copyWith(isAutoLoadCancellationPending: true);
  }

  Future<Publication?> getPublicationDetail(String id) async {
    if (_isDisposed) return null;
    try {
      return await _service.getPublicationDetail(id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Publication>> getWorksByAuthor(
    String authorId, {
    int perPage = 20,
  }) async {
    try {
      return await _service.getWorksByAuthor(authorId, perPage: perPage);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Publication>> getWorksByJournal(
    String journalId, {
    int perPage = 20,
  }) async {
    try {
      return await _service.getWorksByJournal(journalId, perPage: perPage);
    } catch (_) {
      return const [];
    }
  }

  List<Publication> _appendUnique(
    List<Publication> existing,
    List<Publication> incoming,
  ) {
    final merged = <Publication>[...existing];
    final seenIds = existing
        .map((publication) => publication.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final publication in incoming) {
      if (merged.length >= maximumLoadedWorks) break;
      final id = publication.id.trim();
      if (id.isNotEmpty && !seenIds.add(id)) continue;
      merged.add(publication);
    }
    return merged;
  }

  bool _reachedLimit({required int loadedCount, required int totalCount}) {
    if (loadedCount < maximumLoadedWorks) return false;
    return totalCount > loadedCount;
  }

  void _setLoadMoreFailureIfCurrent(
    int requestId,
    String message, {
    bool autoLoadFailed = false,
  }) {
    if (!_isCurrent(requestId)) return;
    state.value = state.value.copyWith(
      isLoadingMore: false,
      isAutoLoading: false,
      isAutoLoadCancellationPending: false,
      autoLoadFailed: autoLoadFailed,
      loadMoreErrorMessage: message,
    );
  }

  void _finishAutoLoadIfCurrent(int requestId) {
    if (!_isCurrent(requestId)) return;
    state.value = state.value.copyWith(
      isLoadingMore: false,
      isAutoLoading: false,
      isAutoLoadCancellationPending: false,
      autoLoadFailed: false,
    );
  }

  void _finishAutoLoadCancellationIfCurrent(int requestId) {
    if (!_isCurrent(requestId)) return;
    state.value = state.value.copyWith(
      isLoadingMore: false,
      isAutoLoading: false,
      isAutoLoadCancellationPending: false,
      autoLoadFailed: false,
      loadMoreErrorMessage: null,
    );
  }

  void _stopAtUnsafeCursorIfCurrent(int requestId) {
    if (!_isCurrent(requestId)) return;
    state.value = state.value.copyWith(
      nextCursor: null,
      isLoadingMore: false,
      isAutoLoading: false,
      isAutoLoadCancellationPending: false,
      autoLoadFailed: false,
      loadMoreErrorMessage:
          'OpenAlex stopped pagination because it returned a repeated cursor. '
          'Run the search again to restart safely.',
    );
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _stateRequestId += 1;
    _autoLoadOperationId += 1;
    state.dispose();
    if (_ownsService) _service.close();
  }

  int _beginStateRequest() {
    final requestId = ++_stateRequestId;
    if (!_isDisposed) {
      state.value = const OpenAlexSearchState(
        status: OpenAlexSearchStatus.loading,
      );
    }
    return requestId;
  }

  bool _isCurrent(int requestId) {
    return !_isDisposed && requestId == _stateRequestId;
  }

  void _setStateIfCurrent(int requestId, OpenAlexSearchState nextState) {
    if (!_isCurrent(requestId)) return;
    state.value = nextState;
  }
}
