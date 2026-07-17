import '../models/keyword_insight.dart';
import '../models/publication.dart';
import '../models/ranked_item.dart';
import '../models/trend_data.dart';
import '../services/analytics_service.dart';

class KeywordDetailViewModel {
  KeywordDetailViewModel(
    this.keyword, {
    AnalyticsService analytics = const AnalyticsService(),
  }) : journals = List<RankedItem>.unmodifiable(
         analytics.getTopJournals(keyword.publications, limit: 8),
       ),
       authors = List<RankedItem>.unmodifiable(
         analytics.getTopAuthors(keyword.publications, limit: 10),
       ),
       publications = List<Publication>.unmodifiable(
         [...keyword.publications]
           ..sort((a, b) => b.citationCount.compareTo(a.citationCount)),
       );

  final KeywordInsight keyword;
  final List<RankedItem> journals;
  final List<RankedItem> authors;
  final List<Publication> publications;

  String get name => keyword.name;
  int get frequency => keyword.frequency;
  int get totalCitations => keyword.totalCitations;
  List<TrendData> get trend => keyword.trend;
}
