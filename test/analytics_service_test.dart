import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/mock/mock_publications.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/models/research_topic.dart';
import 'package:journal_trend_analysis/services/analytics_service.dart';

void main() {
  const service = AnalyticsService();

  group('AnalyticsService', () {
    test('returns safe defaults for empty publication list', () {
      final dashboard = service.generateDashboardData(const []);

      expect(service.getTotalPublications(const []), 0);
      expect(service.getAverageCitationCount(const []), 0);
      expect(service.getPublicationTrendByYear(const []), isEmpty);
      expect(service.getCitationTrendByYear(const []), isEmpty);
      expect(service.getTopicEvolution(const []), isEmpty);
      expect(service.getResearchFrontier(const []), isEmpty);
      expect(
        service.getQuartileDistribution(const []).map((item) => item.count),
        [0, 0, 0, 0],
      );
      expect(service.getMostActiveYear(const []), 0);
      expect(service.getTopInfluentialPapers(const []), isEmpty);
      expect(service.getTopJournals(const []), isEmpty);
      expect(service.getTopAuthors(const []), isEmpty);
      expect(dashboard.totalPublications, 0);
      expect(dashboard.averageCitationCount, 0);
      expect(dashboard.mostActiveYear, 0);
      expect(dashboard.topJournal, 'N/A');
      expect(dashboard.topAuthor, 'N/A');
      expect(dashboard.mostInfluentialPaper, 'N/A');
      expect(dashboard.mostInfluentialPaperCitations, 0);
    });

    test('counts total publications', () {
      expect(service.getTotalPublications(mockPublications), 12);
    });

    test('calculates average citation count', () {
      expect(
        service.getAverageCitationCount(mockPublications),
        closeTo(447.083, 0.001),
      );
    });

    test('groups publication trend by year in ascending order', () {
      final trend = service.getPublicationTrendByYear(mockPublications);

      expect(trend.map((item) => item.year), [2020, 2021, 2022, 2023, 2024]);
      expect(trend.map((item) => item.publicationCount), [1, 1, 2, 5, 3]);
    });

    test('sums citation trend by year in ascending order', () {
      final trend = service.getCitationTrendByYear(mockPublications);

      expect(trend.map((item) => item.year), [2020, 2021, 2022, 2023, 2024]);
      expect(trend.map((item) => item.value), [95, 860, 1550, 1915, 945]);
    });

    test('finds the most active publication year', () {
      expect(service.getMostActiveYear(mockPublications), 2023);
    });

    test('ranks top influential papers by citation count', () {
      final topPapers = service.getTopInfluentialPapers(mockPublications);

      expect(
        topPapers.first.name,
        'Citation-Aware Topic Discovery in Open Scholarly Graphs',
      );
      expect(topPapers.first.count, 1240);
      expect(topPapers, hasLength(5));
    });

    test('ranks top journals by publication count', () {
      final topJournals = service.getTopJournals(mockPublications);

      expect(topJournals.first.name, 'Journal of AI Research');
      expect(topJournals.first.count, 4);
      expect(topJournals, hasLength(5));
    });

    test('skips unknown or blank journals', () {
      const publications = [
        Publication(
          id: 'unknown-1',
          title: 'Unknown Journal Paper',
          publicationYear: 2024,
          citationCount: 10,
          journalName: 'Unknown Journal',
          authors: ['A'],
        ),
        Publication(
          id: 'unknown-2',
          title: 'Blank Journal Paper',
          publicationYear: 2024,
          citationCount: 20,
          journalName: ' ',
          authors: ['A'],
        ),
      ];

      expect(service.getTopJournals(publications), isEmpty);
    });

    test('keeps unknown journals in quartile distribution total', () {
      const publications = [
        Publication(
          id: 'known-1',
          title: 'Known Journal Paper',
          publicationYear: 2024,
          citationCount: 30,
          journalName: 'Journal A',
          authors: ['A'],
        ),
        Publication(
          id: 'unknown-1',
          title: 'Unknown Journal Paper',
          publicationYear: 2024,
          citationCount: 10,
          journalName: 'Unknown Journal',
          authors: ['B'],
        ),
        Publication(
          id: 'blank-1',
          title: 'Blank Journal Paper',
          publicationYear: 2024,
          citationCount: 5,
          journalName: ' ',
          authors: ['C'],
        ),
      ];

      final quartiles = service.getQuartileDistribution(publications);

      expect(quartiles.fold<int>(0, (sum, item) => sum + item.count), 3);
      expect(quartiles.map((item) => item.count), [1, 0, 0, 2]);
    });

    test('ranks top authors by publication count', () {
      final topAuthors = service.getTopAuthors(mockPublications);

      expect(topAuthors.first.name, 'Linh Nguyen');
      expect(topAuthors.first.count, 7);
      expect(topAuthors, hasLength(5));
    });

    test('builds keyword, landscape, author impact, and heatmap data', () {
      const publications = [
        Publication(
          id: '1',
          title: 'Paper 1',
          publicationYear: 2024,
          citationCount: 20,
          journalName: 'Journal A',
          authors: ['An Nguyen'],
          keywords: ['AI', 'Healthcare'],
          topics: [
            ResearchTopic(
              name: 'Clinical AI',
              field: 'Medicine',
              domain: 'Health Sciences',
            ),
          ],
        ),
        Publication(
          id: '2',
          title: 'Paper 2',
          publicationYear: 2024,
          citationCount: 30,
          journalName: 'Journal A',
          authors: ['An Nguyen', 'Binh Tran'],
          keywords: ['AI'],
          topics: [
            ResearchTopic(
              name: 'Clinical AI',
              field: 'Medicine',
              domain: 'Health Sciences',
            ),
          ],
        ),
      ];

      expect(service.getTopKeywords(publications).first.name, 'AI');
      expect(service.getTopKeywords(publications).first.count, 2);
      expect(
        service.getResearchLandscape(publications).first.field,
        'Medicine',
      );
      expect(service.getResearchLandscape(publications).first.count, 2);
      final evolution = service.getTopicEvolution(publications);
      expect(evolution.first.name, 'Clinical AI');
      expect(evolution.first.points.first.year, 2024);
      expect(evolution.first.points.first.value, 2);
      final frontier = service.getResearchFrontier(publications);
      expect(frontier.first.keyword, 'AI');
      expect(frontier.first.year, 2024);
      expect(frontier.first.count, 2);
      expect(frontier.first.growth, 2);
      expect(
        service.getQuartileDistribution(publications).map((item) => item.count),
        [2, 0, 0, 0],
      );
      expect(
        service.getAuthorProductivityImpact(publications).first.citationCount,
        50,
      );

      final matrix = service.getJournalTopicMatrix(publications);
      expect(matrix.journals, ['Journal A']);
      expect(matrix.topics, ['Clinical AI']);
      expect(matrix.values, [
        [2],
      ]);
    });

    test('generates complete dashboard data', () {
      final dashboard = service.generateDashboardData(mockPublications);

      expect(dashboard.totalPublications, 12);
      expect(dashboard.averageCitationCount, closeTo(447.083, 0.001));
      expect(dashboard.mostActiveYear, 2023);
      expect(dashboard.topJournal, 'Journal of AI Research');
      expect(dashboard.topAuthor, 'Linh Nguyen');
      expect(
        dashboard.mostInfluentialPaper,
        'Citation-Aware Topic Discovery in Open Scholarly Graphs',
      );
      expect(dashboard.mostInfluentialPaperCitations, 1240);
    });
  });
}
