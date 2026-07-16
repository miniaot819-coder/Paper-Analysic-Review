import 'publication.dart';

const Object _notProvided = Object();

enum OpenAlexSearchStatus { idle, loading, success, failure }

class OpenAlexSearchState {
  const OpenAlexSearchState({
    required this.status,
    this.publications = const [],
    this.totalCount = 0,
    this.nextCursor,
    this.isLoadingMore = false,
    this.isAutoLoading = false,
    this.isAutoLoadCancellationPending = false,
    this.autoLoadFailed = false,
    this.errorMessage,
    this.loadMoreErrorMessage,
    this.reachedResultLimit = false,
  });

  const OpenAlexSearchState.idle()
    : status = OpenAlexSearchStatus.idle,
      publications = const [],
      totalCount = 0,
      nextCursor = null,
      isLoadingMore = false,
      isAutoLoading = false,
      isAutoLoadCancellationPending = false,
      autoLoadFailed = false,
      errorMessage = null,
      loadMoreErrorMessage = null,
      reachedResultLimit = false;

  final OpenAlexSearchStatus status;
  final List<Publication> publications;
  final int totalCount;
  final String? nextCursor;
  final bool isLoadingMore;
  final bool isAutoLoading;
  final bool isAutoLoadCancellationPending;
  final bool autoLoadFailed;
  final String? errorMessage;
  final String? loadMoreErrorMessage;
  final bool reachedResultLimit;

  bool get isLoading => status == OpenAlexSearchStatus.loading;
  bool get hasError => status == OpenAlexSearchStatus.failure;
  int get loadedCount => publications.length;
  int get displayTotalCount =>
      totalCount < loadedCount ? loadedCount : totalCount;
  bool get hasMore =>
      status == OpenAlexSearchStatus.success &&
      !reachedResultLimit &&
      nextCursor != null &&
      nextCursor!.isNotEmpty;
  bool get canLoadMore => hasMore && !isLoadingMore;

  OpenAlexSearchState copyWith({
    OpenAlexSearchStatus? status,
    List<Publication>? publications,
    int? totalCount,
    Object? nextCursor = _notProvided,
    bool? isLoadingMore,
    bool? isAutoLoading,
    bool? isAutoLoadCancellationPending,
    bool? autoLoadFailed,
    Object? errorMessage = _notProvided,
    Object? loadMoreErrorMessage = _notProvided,
    bool? reachedResultLimit,
  }) {
    return OpenAlexSearchState(
      status: status ?? this.status,
      publications: publications ?? this.publications,
      totalCount: totalCount ?? this.totalCount,
      nextCursor: identical(nextCursor, _notProvided)
          ? this.nextCursor
          : nextCursor as String?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isAutoLoading: isAutoLoading ?? this.isAutoLoading,
      isAutoLoadCancellationPending:
          isAutoLoadCancellationPending ?? this.isAutoLoadCancellationPending,
      autoLoadFailed: autoLoadFailed ?? this.autoLoadFailed,
      errorMessage: identical(errorMessage, _notProvided)
          ? this.errorMessage
          : errorMessage as String?,
      loadMoreErrorMessage: identical(loadMoreErrorMessage, _notProvided)
          ? this.loadMoreErrorMessage
          : loadMoreErrorMessage as String?,
      reachedResultLimit: reachedResultLimit ?? this.reachedResultLimit,
    );
  }
}
