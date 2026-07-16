import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analysis/repositories/openalex_repository.dart';
import 'package:journal_trend_analysis/services/analytics_data_service.dart';
import 'package:journal_trend_analysis/services/openalex_service.dart';

void main() {
  group('AnalyticsDataService', () {
    late OpenAlexRepository repository;

    tearDown(() {
      repository.dispose();
    });

    OpenAlexRepository createRepository(http.Response Function() response) {
      final service = OpenAlexService(
        client: MockClient((request) async {
          expect(request.url.queryParameters['search'], 'machine learning');
          return response();
        }),
        delay: (_) async {},
      );

      return OpenAlexRepository(service: service);
    }

    test('generates dashboard data from OpenAlex publications', () async {
      repository = createRepository(
        () => http.Response(_openAlexSearchResponse, 200),
      );
      final service = AnalyticsDataService(repository: repository);

      final dashboard = await service.generateDashboardFromTopic(
        'machine learning',
      );

      expect(dashboard.totalPublications, 3);
      expect(dashboard.averageCitationCount, closeTo(40, 0.001));
      expect(dashboard.mostActiveYear, 2024);
      expect(dashboard.topJournal, 'Journal of Data Science');
      expect(dashboard.topAuthor, 'Linh Nguyen');
      expect(dashboard.mostInfluentialPaper, 'Citation-Aware Search');
      expect(dashboard.mostInfluentialPaperCitations, 70);
    });

    test(
      'returns trend and ranking lists from OpenAlex publications',
      () async {
        repository = createRepository(
          () => http.Response(_openAlexSearchResponse, 200),
        );
        final service = AnalyticsDataService(repository: repository);

        final trend = await service.getTrendFromTopic('machine learning');
        final topPapers = await service.getTopPapersFromTopic(
          'machine learning',
          limit: 2,
        );
        final topJournals = await service.getTopJournalsFromTopic(
          'machine learning',
          limit: 1,
        );
        final topAuthors = await service.getTopAuthorsFromTopic(
          'machine learning',
          limit: 1,
        );

        expect(trend.map((item) => item.year), [2023, 2024]);
        expect(trend.map((item) => item.publicationCount), [1, 2]);
        expect(topPapers.map((item) => item.name), [
          'Citation-Aware Search',
          'Research Trend Dashboards',
        ]);
        expect(topJournals.single.name, 'Journal of Data Science');
        expect(topJournals.single.count, 2);
        expect(topAuthors.single.name, 'Linh Nguyen');
        expect(topAuthors.single.count, 2);
      },
    );

    test('returns safe defaults when OpenAlex fails', () async {
      repository = createRepository(
        () => http.Response('Internal Server Error', 500),
      );
      final service = AnalyticsDataService(repository: repository);

      final dashboard = await service.generateDashboardFromTopic(
        'machine learning',
      );
      final trend = await service.getTrendFromTopic('machine learning');
      final topPapers = await service.getTopPapersFromTopic('machine learning');

      expect(dashboard.totalPublications, 0);
      expect(dashboard.averageCitationCount, 0);
      expect(dashboard.mostActiveYear, 0);
      expect(dashboard.topJournal, 'N/A');
      expect(dashboard.topAuthor, 'N/A');
      expect(dashboard.mostInfluentialPaper, 'N/A');
      expect(dashboard.mostInfluentialPaperCitations, 0);
      expect(trend, isEmpty);
      expect(topPapers, isEmpty);
    });
  });
}

const _openAlexSearchResponse = '''
{
  "meta": {"count": 3, "next_cursor": null},
  "results": [
    {
      "id": "https://openalex.org/W1",
      "title": "Research Trend Dashboards",
      "publication_year": 2024,
      "cited_by_count": 35,
      "primary_location": {
        "source": {
          "display_name": "Journal of Data Science"
        }
      },
      "authorships": [
        {
          "author": {
            "display_name": "Linh Nguyen"
          }
        },
        {
          "author": {
            "display_name": "An Tran"
          }
        }
      ]
    },
    {
      "id": "https://openalex.org/W2",
      "title": "Citation-Aware Search",
      "publication_year": 2024,
      "cited_by_count": 70,
      "primary_location": {
        "source": {
          "display_name": "Journal of Data Science"
        }
      },
      "authorships": [
        {
          "author": {
            "display_name": "Linh Nguyen"
          }
        }
      ]
    },
    {
      "id": "https://openalex.org/W3",
      "title": "Open Research Metadata",
      "publication_year": 2023,
      "cited_by_count": 15,
      "primary_location": {
        "source": {
          "display_name": "Information Systems Review"
        }
      },
      "authorships": [
        {
          "author": {
            "display_name": "Mai Vo"
          }
        }
      ]
    }
  ]
}
''';
