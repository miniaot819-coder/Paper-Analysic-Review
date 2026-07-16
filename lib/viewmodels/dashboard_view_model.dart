import '../firebase/remote_config_service.dart';
import '../models/dashboard_data.dart';
import '../models/publication.dart';
import '../models/ranked_item.dart';
import '../models/trend_data.dart';
import '../services/analytics_service.dart';

class DashboardPresentationData {
  const DashboardPresentationData({
    required this.dashboard,
    required this.trend,
    required this.topJournals,
    required this.topAuthors,
    required this.mostInfluentialPublication,
  });

  final DashboardData dashboard;
  final List<TrendData> trend;
  final List<RankedItem> topJournals;
  final List<RankedItem> topAuthors;
  final Publication? mostInfluentialPublication;
}

class DashboardViewModel {
  DashboardViewModel({
    AnalyticsService analytics = const AnalyticsService(),
    RemoteConfigGateway? remoteConfig,
  }) : _analytics = analytics,
       _remoteConfig = remoteConfig ?? RemoteConfigService.instance;

  final AnalyticsService _analytics;
  final RemoteConfigGateway _remoteConfig;

  List<Publication>? _cachedPublications;
  int? _cachedJournalLimit;
  DashboardPresentationData? _cachedPresentation;

  DashboardPresentationData presentationFor(List<Publication> publications) {
    final journalLimit = _remoteConfig.maxJournals;
    if (identical(_cachedPublications, publications) &&
        _cachedJournalLimit == journalLimit &&
        _cachedPresentation != null) {
      return _cachedPresentation!;
    }

    final mostInfluential = publications.isEmpty
        ? null
        : ([
            ...publications,
          ]..sort((a, b) => b.citationCount.compareTo(a.citationCount))).first;
    final presentation = DashboardPresentationData(
      dashboard: _analytics.generateDashboardData(publications),
      trend: List<TrendData>.unmodifiable(
        _analytics.getPublicationTrendByYear(publications),
      ),
      topJournals: List<RankedItem>.unmodifiable(
        _analytics.getTopJournals(publications, limit: journalLimit),
      ),
      topAuthors: List<RankedItem>.unmodifiable(
        _analytics.getTopAuthors(publications),
      ),
      mostInfluentialPublication: mostInfluential,
    );

    _cachedPublications = publications;
    _cachedJournalLimit = journalLimit;
    _cachedPresentation = presentation;
    return presentation;
  }
}
