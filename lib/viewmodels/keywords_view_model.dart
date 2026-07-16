import '../models/keyword_insight.dart';
import '../models/publication.dart';
import '../models/trend_data.dart';
import 'research_tab_view_model.dart';

class KeywordsViewModel extends ResearchTabViewModel {
  KeywordsViewModel({
    super.initialTopic = 'Artificial Intelligence',
    super.repository,
  });

  List<Publication>? _cachedPublications;
  List<KeywordInsight> _cachedKeywords = const [];
  List<KeywordInsight> _cachedTrendingKeywords = const [];

  List<KeywordInsight> get keywords {
    final publications = state.publications;
    if (identical(_cachedPublications, publications)) {
      return _cachedKeywords;
    }

    final grouped = <String, List<Publication>>{};
    final displayNames = <String, String>{};

    for (final publication in publications) {
      final sourceKeywords = publication.keywords.isNotEmpty
          ? publication.keywords
          : publication.topics.map((topic) => topic.name).toList();
      for (final rawKeyword in sourceKeywords.toSet()) {
        final name = rawKeyword.trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        displayNames.putIfAbsent(key, () => name);
        grouped.putIfAbsent(key, () => []).add(publication);
      }
    }

    final result =
        grouped.entries.map((entry) {
          final publications = entry.value;
          final countsByYear = <int, int>{};
          for (final publication in publications) {
            if (publication.publicationYear <= 0) continue;
            countsByYear[publication.publicationYear] =
                (countsByYear[publication.publicationYear] ?? 0) + 1;
          }
          final years = countsByYear.keys.toList()..sort();
          final trend = years
              .map(
                (year) => TrendData(
                  year: year,
                  publicationCount: countsByYear[year]!,
                ),
              )
              .toList();
          final latestYear = years.isEmpty ? 0 : years.last;
          final growth = latestYear == 0
              ? 0
              : (countsByYear[latestYear] ?? 0) -
                    (countsByYear[latestYear - 1] ?? 0);
          return KeywordInsight(
            name: displayNames[entry.key]!,
            publications: publications,
            trend: trend,
            growth: growth,
          );
        }).toList()..sort((a, b) {
          final byFrequency = b.frequency.compareTo(a.frequency);
          return byFrequency != 0 ? byFrequency : a.name.compareTo(b.name);
        });
    _cachedPublications = publications;
    _cachedKeywords = List<KeywordInsight>.unmodifiable(result);
    final trending = [...result]
      ..sort((a, b) {
        final byGrowth = b.growth.compareTo(a.growth);
        return byGrowth != 0 ? byGrowth : b.frequency.compareTo(a.frequency);
      });
    _cachedTrendingKeywords = List<KeywordInsight>.unmodifiable(trending);
    return _cachedKeywords;
  }

  List<KeywordInsight> get trendingKeywords {
    keywords;
    return _cachedTrendingKeywords;
  }
}
