import 'dart:math' as math;

import '../models/dashboard_data.dart';
import '../models/author_impact.dart';
import '../models/journal_topic_matrix.dart';
import '../models/landscape_item.dart';
import '../models/publication.dart';
import '../models/ranked_item.dart';
import '../models/research_frontier_point.dart';
import '../models/trend_data.dart';
import '../models/topic_evolution_series.dart';
import '../models/year_metric.dart';

class AnalyticsService {
  const AnalyticsService();

  int getTotalPublications(List<Publication> publications) {
    return publications.length;
  }

  double getAverageCitationCount(List<Publication> publications) {
    if (publications.isEmpty) return 0;

    final totalCitations = publications.fold<int>(
      0,
      (sum, publication) => sum + publication.citationCount,
    );

    return totalCitations / publications.length;
  }

  List<TrendData> getPublicationTrendByYear(List<Publication> publications) {
    final yearCount = <int, int>{};

    for (final publication in publications) {
      yearCount[publication.publicationYear] =
          (yearCount[publication.publicationYear] ?? 0) + 1;
    }

    final result =
        yearCount.entries
            .map(
              (entry) =>
                  TrendData(year: entry.key, publicationCount: entry.value),
            )
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    return result;
  }

  List<YearMetric> getCitationTrendByYear(List<Publication> publications) {
    final citationByYear = <int, int>{};

    for (final publication in publications) {
      if (publication.publicationYear <= 0) continue;
      citationByYear[publication.publicationYear] =
          (citationByYear[publication.publicationYear] ?? 0) +
          publication.citationCount;
    }

    final result =
        citationByYear.entries
            .map((entry) => YearMetric(year: entry.key, value: entry.value))
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    return result;
  }

  int getMostActiveYear(List<Publication> publications) {
    final trend = getPublicationTrendByYear(publications);
    if (trend.isEmpty) return 0;

    trend.sort((a, b) {
      final countComparison = b.publicationCount.compareTo(a.publicationCount);
      if (countComparison != 0) return countComparison;
      return b.year.compareTo(a.year);
    });

    return trend.first.year;
  }

  List<RankedItem> getTopInfluentialPapers(
    List<Publication> publications, {
    int limit = 5,
  }) {
    if (limit <= 0) return const [];

    final sorted = [...publications]
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));

    return sorted.take(limit).map((publication) {
      return RankedItem(
        name: publication.title,
        count: publication.citationCount,
        subtitle: publication.journalName,
      );
    }).toList();
  }

  List<RankedItem> getTopJournals(
    List<Publication> publications, {
    int limit = 5,
  }) {
    if (limit <= 0) return const [];

    final journalCount = <String, int>{};
    final journalIds = <String, String>{};

    for (final publication in publications) {
      final journal = publication.journalName.trim();
      if (journal.isEmpty || journal.toLowerCase() == 'unknown') {
        continue;
      }
      if (journal.toLowerCase() == 'unknown journal') {
        continue;
      }

      journalCount[journal] = (journalCount[journal] ?? 0) + 1;
      final journalId = publication.journalId?.trim();
      if (journalId != null && journalId.isNotEmpty) {
        journalIds.putIfAbsent(journal, () => journalId);
      }
    }

    final result =
        journalCount.entries
            .map(
              (entry) => RankedItem(
                name: entry.key,
                count: entry.value,
                subtitle: 'publications',
                id: journalIds[entry.key],
              ),
            )
            .toList()
          ..sort((a, b) {
            final countComparison = b.count.compareTo(a.count);
            if (countComparison != 0) return countComparison;
            return a.name.compareTo(b.name);
          });

    return result.take(limit).toList();
  }

  List<RankedItem> getTopAuthors(
    List<Publication> publications, {
    int limit = 5,
  }) {
    if (limit <= 0) return const [];

    final authorCount = <String, int>{};
    final authorIds = <String, String>{};

    for (final publication in publications) {
      for (final author in publication.authors) {
        final authorName = author.trim();
        if (authorName.isEmpty) continue;

        authorCount[authorName] = (authorCount[authorName] ?? 0) + 1;
        final authorId = publication.authorIdsByName[authorName]?.trim();
        if (authorId != null && authorId.isNotEmpty) {
          authorIds.putIfAbsent(authorName, () => authorId);
        }
      }
    }

    final result =
        authorCount.entries
            .map(
              (entry) => RankedItem(
                name: entry.key,
                count: entry.value,
                subtitle: 'publications',
                id: authorIds[entry.key],
              ),
            )
            .toList()
          ..sort((a, b) {
            final countComparison = b.count.compareTo(a.count);
            if (countComparison != 0) return countComparison;
            return a.name.compareTo(b.name);
          });

    return result.take(limit).toList();
  }

  List<RankedItem> getTopKeywords(
    List<Publication> publications, {
    int limit = 5,
  }) {
    final counts = <String, int>{};
    for (final publication in publications) {
      for (final keyword in publication.keywords.toSet()) {
        counts[keyword] = (counts[keyword] ?? 0) + 1;
      }
    }

    final result =
        counts.entries
            .map((entry) => RankedItem(name: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            return byCount != 0 ? byCount : a.name.compareTo(b.name);
          });
    return result.take(limit).toList();
  }

  List<TopicEvolutionSeries> getTopicEvolution(
    List<Publication> publications, {
    int topicLimit = 3,
  }) {
    final validPublications = publications
        .where((publication) => publication.publicationYear > 0)
        .toList();
    if (validPublications.isEmpty || topicLimit <= 0) return const [];

    final topicTotals = <String, int>{};
    for (final publication in validPublications) {
      for (final topic in publication.topics.map((item) => item.name).toSet()) {
        topicTotals[topic] = (topicTotals[topic] ?? 0) + 1;
      }
    }

    final rankedTopics = topicTotals.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final selectedTopics = rankedTopics
        .take(topicLimit)
        .map((entry) => entry.key)
        .toList();
    final years =
        validPublications.map((item) => item.publicationYear).toSet().toList()
          ..sort();

    return selectedTopics.map((topic) {
      final counts = <int, int>{};
      for (final publication in validPublications) {
        if (publication.topics.any((item) => item.name == topic)) {
          counts[publication.publicationYear] =
              (counts[publication.publicationYear] ?? 0) + 1;
        }
      }
      return TopicEvolutionSeries(
        name: topic,
        points: years
            .map((year) => YearMetric(year: year, value: counts[year] ?? 0))
            .toList(),
      );
    }).toList();
  }

  List<ResearchFrontierPoint> getResearchFrontier(
    List<Publication> publications, {
    int limit = 12,
  }) {
    if (limit <= 0) return const [];

    final countsByKeywordAndYear = <String, Map<int, int>>{};
    for (final publication in publications) {
      if (publication.publicationYear <= 0) continue;
      for (final keyword in publication.keywords.toSet()) {
        final yearlyCounts = countsByKeywordAndYear.putIfAbsent(
          keyword,
          () => <int, int>{},
        );
        yearlyCounts[publication.publicationYear] =
            (yearlyCounts[publication.publicationYear] ?? 0) + 1;
      }
    }

    final points = <ResearchFrontierPoint>[];
    for (final entry in countsByKeywordAndYear.entries) {
      final years = entry.value.keys.toList()..sort();
      for (final year in years) {
        final count = entry.value[year] ?? 0;
        final previousCount = entry.value[year - 1] ?? 0;
        final growth = count - previousCount;
        if (growth <= 0) continue;

        points.add(
          ResearchFrontierPoint(
            keyword: entry.key,
            year: year,
            count: count,
            growth: growth,
          ),
        );
      }
    }

    points.sort((a, b) {
      final byGrowth = b.growth.compareTo(a.growth);
      if (byGrowth != 0) return byGrowth;
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return b.year.compareTo(a.year);
    });
    return points.take(limit).toList();
  }

  List<RankedItem> getQuartileDistribution(List<Publication> publications) {
    final publicationsByJournal = <String, List<Publication>>{};
    var unknownJournalCount = 0;

    for (final publication in publications) {
      final journal = publication.journalName.trim();
      if (journal.isEmpty || journal.toLowerCase().startsWith('unknown')) {
        unknownJournalCount++;
        continue;
      }
      publicationsByJournal.putIfAbsent(journal, () => []).add(publication);
    }

    final rankedJournals = publicationsByJournal.entries.toList()
      ..sort((a, b) {
        double averageCitation(MapEntry<String, List<Publication>> entry) {
          final total = entry.value.fold<int>(
            0,
            (sum, publication) => sum + publication.citationCount,
          );
          return total / entry.value.length;
        }

        return averageCitation(b).compareTo(averageCitation(a));
      });

    final counts = List<int>.filled(4, 0);
    for (var index = 0; index < rankedJournals.length; index++) {
      final quartileIndex = math.min(3, index * 4 ~/ rankedJournals.length);
      counts[quartileIndex] += rankedJournals[index].value.length;
    }
    counts[3] += unknownJournalCount;

    return List.generate(
      4,
      (index) => RankedItem(name: 'Q${index + 1}', count: counts[index]),
    );
  }

  List<LandscapeItem> getResearchLandscape(
    List<Publication> publications, {
    int limit = 8,
  }) {
    final counts = <String, int>{};
    for (final publication in publications) {
      final uniqueAreas = publication.topics
          .map((topic) => '${topic.domain}\u0000${topic.field}')
          .toSet();
      for (final area in uniqueAreas) {
        counts[area] = (counts[area] ?? 0) + 1;
      }
    }

    final result = counts.entries.map((entry) {
      final parts = entry.key.split('\u0000');
      return LandscapeItem(
        domain: parts.first,
        field: parts.last,
        count: entry.value,
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));
    return result.take(limit).toList();
  }

  List<AuthorImpact> getAuthorProductivityImpact(
    List<Publication> publications, {
    int limit = 12,
  }) {
    final publicationCounts = <String, int>{};
    final citationCounts = <String, int>{};
    for (final publication in publications) {
      for (final author in publication.authors.toSet()) {
        publicationCounts[author] = (publicationCounts[author] ?? 0) + 1;
        citationCounts[author] =
            (citationCounts[author] ?? 0) + publication.citationCount;
      }
    }

    final result =
        publicationCounts.entries
            .map(
              (entry) => AuthorImpact(
                name: entry.key,
                publicationCount: entry.value,
                citationCount: citationCounts[entry.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) {
            final byPublications = b.publicationCount.compareTo(
              a.publicationCount,
            );
            return byPublications != 0
                ? byPublications
                : b.citationCount.compareTo(a.citationCount);
          });
    return result.take(limit).toList();
  }

  JournalTopicMatrix getJournalTopicMatrix(
    List<Publication> publications, {
    int journalLimit = 4,
    int topicLimit = 5,
  }) {
    final journals = getTopJournals(
      publications,
      limit: journalLimit,
    ).map((item) => item.name).toList();

    final topicCounts = <String, int>{};
    for (final publication in publications) {
      for (final topic in publication.topics.map((item) => item.name).toSet()) {
        topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
      }
    }
    final topicEntries = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topics = topicEntries
        .take(topicLimit)
        .map((entry) => entry.key)
        .toList();

    final values = journals.map((journal) {
      return topics.map((topic) {
        return publications.where((publication) {
          return publication.journalName == journal &&
              publication.topics.any((item) => item.name == topic);
        }).length;
      }).toList();
    }).toList();

    return JournalTopicMatrix(
      journals: journals,
      topics: topics,
      values: values,
    );
  }

  DashboardData generateDashboardData(List<Publication> publications) {
    if (publications.isEmpty) {
      return const DashboardData(
        totalPublications: 0,
        averageCitationCount: 0,
        mostActiveYear: 0,
        topJournal: 'N/A',
        topAuthor: 'N/A',
        mostInfluentialPaper: 'N/A',
        mostInfluentialPaperCitations: 0,
      );
    }

    final topJournals = getTopJournals(publications, limit: 1);
    final topAuthors = getTopAuthors(publications, limit: 1);
    final topPapers = getTopInfluentialPapers(publications, limit: 1);

    return DashboardData(
      totalPublications: getTotalPublications(publications),
      averageCitationCount: getAverageCitationCount(publications),
      mostActiveYear: getMostActiveYear(publications),
      topJournal: topJournals.isNotEmpty ? topJournals.first.name : 'N/A',
      topAuthor: topAuthors.isNotEmpty ? topAuthors.first.name : 'N/A',
      mostInfluentialPaper: topPapers.isNotEmpty ? topPapers.first.name : 'N/A',
      mostInfluentialPaperCitations: topPapers.isNotEmpty
          ? topPapers.first.count
          : 0,
    );
  }
}
