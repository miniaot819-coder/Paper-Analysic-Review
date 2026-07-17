import 'dart:async';

import 'package:flutter/foundation.dart';

import '../firebase/analytics_tracking_service.dart';
import '../models/openalex_search_state.dart';
import '../models/publication.dart';
import '../repositories/openalex_repository.dart';

class ResearchTabViewModel extends ChangeNotifier {
  ResearchTabViewModel({
    required String initialTopic,
    int initialPublicationLimit = OpenAlexRepository.defaultPageSize,
    OpenAlexRepository? repository,
  }) : _topic = initialTopic.trim(),
       _publicationLimit = _normalizeLimitValue(initialPublicationLimit),
       _ownsRepository = repository == null,
       _repository = repository ?? OpenAlexRepository() {
    _repository.state.addListener(_forwardRepositoryState);
  }

  final OpenAlexRepository _repository;
  final bool _ownsRepository;

  String _topic;
  int _publicationLimit;
  bool _hasLoaded = false;
  final List<String> _recentSearches = <String>[];

  String get topic => _topic;
  int get publicationLimit => _publicationLimit;
  int get pageSize => _publicationLimit;
  int get maximumLoadedWorks => _repository.maximumLoadedWorks;
  bool get hasLoaded => _hasLoaded;
  OpenAlexSearchState get state => _repository.state.value;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  Future<void> loadInitial() async {
    if (_hasLoaded) return;
    await search(_topic, perPage: _publicationLimit, trackAnalytics: false);
  }

  Future<void> search(
    String topic, {
    int? perPage,
    bool trackAnalytics = true,
  }) async {
    final normalizedTopic = topic.trim();
    if (normalizedTopic.isEmpty) return;

    final normalizedLimit = _normalizeLimit(perPage ?? _publicationLimit);
    _topic = normalizedTopic;
    _publicationLimit = normalizedLimit;
    _hasLoaded = true;
    _rememberSearch(normalizedTopic);
    notifyListeners();

    if (trackAnalytics) {
      unawaited(
        AnalyticsTrackingService.instance.logSearchTopic(normalizedTopic),
      );
    }

    await _repository.searchTopic(normalizedTopic, perPage: normalizedLimit);
  }

  Future<void> loadMore() async {
    await _repository.loadMore();
  }

  Future<void> loadUpToLimit() async {
    await _repository.loadUpToLimit();
  }

  void cancelLoadUpToLimit() {
    _repository.cancelLoadUpToLimit();
  }

  Future<void> retryLoadMore() {
    return state.autoLoadFailed ? loadUpToLimit() : loadMore();
  }

  int normalizePublicationLimit(String rawValue) {
    final parsed = int.tryParse(rawValue.trim());
    return _normalizeLimit(parsed ?? OpenAlexRepository.defaultPageSize);
  }

  void clearRecentSearches() {
    if (_recentSearches.isEmpty) return;
    _recentSearches.clear();
    notifyListeners();
  }

  Future<List<Publication>> getWorksByAuthor(
    String authorId, {
    int perPage = 20,
  }) {
    return _repository.getWorksByAuthor(authorId, perPage: perPage);
  }

  Future<List<Publication>> getWorksByJournal(
    String journalId, {
    int perPage = 20,
  }) {
    return _repository.getWorksByJournal(journalId, perPage: perPage);
  }

  void _rememberSearch(String topic) {
    _recentSearches.remove(topic);
    _recentSearches.insert(0, topic);
    if (_recentSearches.length > 4) {
      _recentSearches.removeLast();
    }
  }

  int _normalizeLimit(int value) {
    return _normalizeLimitValue(value);
  }

  static int _normalizeLimitValue(int value) {
    if (value < 1) return OpenAlexRepository.defaultPageSize;
    return value > OpenAlexRepository.defaultPageSize
        ? OpenAlexRepository.defaultPageSize
        : value;
  }

  void _forwardRepositoryState() {
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.state.removeListener(_forwardRepositoryState);
    if (_ownsRepository) _repository.dispose();
    super.dispose();
  }
}
