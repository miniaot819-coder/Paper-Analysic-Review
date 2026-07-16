import '../models/dashboard_data.dart';
import '../models/ranked_item.dart';
import '../models/trend_data.dart';
import '../repositories/openalex_repository.dart';
import 'analytics_service.dart';

class AnalyticsDataService {
  const AnalyticsDataService({
    required OpenAlexRepository repository,
    AnalyticsService analyticsService = const AnalyticsService(),
  }) : _repository = repository,
       _analyticsService = analyticsService;

  final OpenAlexRepository _repository;
  final AnalyticsService _analyticsService;

  Future<DashboardData> generateDashboardFromTopic(String keyword) async {
    final publications = await _repository.searchTopic(keyword);
    return _analyticsService.generateDashboardData(publications);
  }

  Future<List<TrendData>> getTrendFromTopic(String keyword) async {
    final publications = await _repository.searchTopic(keyword);
    return _analyticsService.getPublicationTrendByYear(publications);
  }

  Future<List<RankedItem>> getTopPapersFromTopic(
    String keyword, {
    int limit = 5,
  }) async {
    final publications = await _repository.searchTopic(keyword);
    return _analyticsService.getTopInfluentialPapers(
      publications,
      limit: limit,
    );
  }

  Future<List<RankedItem>> getTopJournalsFromTopic(
    String keyword, {
    int limit = 5,
  }) async {
    final publications = await _repository.searchTopic(keyword);
    return _analyticsService.getTopJournals(publications, limit: limit);
  }

  Future<List<RankedItem>> getTopAuthorsFromTopic(
    String keyword, {
    int limit = 5,
  }) async {
    final publications = await _repository.searchTopic(keyword);
    return _analyticsService.getTopAuthors(publications, limit: limit);
  }
}
