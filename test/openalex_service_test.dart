import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analysis/services/openalex_service.dart';

void main() {
  group('OpenAlexService', () {
    test('searchTopicPage parses results and pagination metadata', () async {
      final service = OpenAlexService(
        client: MockClient((request) async {
          expect(request.url.queryParameters['search'], 'machine learning');
          expect(request.url.queryParameters['per_page'], '100');
          expect(request.url.queryParameters['cursor'], '*');
          expect(request.url.queryParameters.containsKey('api_key'), isFalse);

          return http.Response('''
          {
            "meta": {
              "count": 321,
              "next_cursor": "cursor-2",
              "cost_usd": 0.001
            },
            "results": [
              {
                "id": "https://openalex.org/W123",
                "title": "Machine Learning for Research Trends",
                "publication_year": 2024,
                "cited_by_count": 42,
                "doi": "https://doi.org/10.1234/example",
                "primary_location": {
                  "source": {
                    "id": "https://openalex.org/S123",
                    "display_name": "Journal of Data Science"
                  }
                },
                "authorships": [
                  {
                    "author": {
                      "id": "https://openalex.org/A123",
                      "display_name": "Linh Nguyen"
                    }
                  },
                  {
                    "author": {
                      "id": "https://openalex.org/A456",
                      "display_name": "An Tran"
                    }
                  }
                ],
                "abstract_inverted_index": {
                  "Research": [0],
                  "trends": [1],
                  "matter": [2]
                },
                "keywords": [
                  {"display_name": "Machine learning", "score": 0.91}
                ],
                "topics": [
                  {
                    "display_name": "Machine Learning Applications",
                    "field": {"display_name": "Computer Science"},
                    "domain": {"display_name": "Physical Sciences"}
                  }
                ]
              }
            ]
          }
          ''', 200);
        }),
      );

      final page = await service.searchTopicPage('machine learning');
      final publications = page.items;

      expect(publications, hasLength(1));
      expect(page.totalCount, 321);
      expect(page.nextCursor, 'cursor-2');
      expect(page.costUsd, 0.001);
      expect(publications.first.id, 'https://openalex.org/W123');
      expect(publications.first.title, 'Machine Learning for Research Trends');
      expect(publications.first.publicationYear, 2024);
      expect(publications.first.citationCount, 42);
      expect(publications.first.journalName, 'Journal of Data Science');
      expect(publications.first.journalId, 'https://openalex.org/S123');
      expect(publications.first.authors, ['Linh Nguyen', 'An Tran']);
      expect(publications.first.authorIdsByName, {
        'Linh Nguyen': 'https://openalex.org/A123',
        'An Tran': 'https://openalex.org/A456',
      });
      expect(publications.first.doi, 'https://doi.org/10.1234/example');
      expect(publications.first.abstractText, 'Research trends matter');
      expect(publications.first.keywords, ['Machine learning']);
      expect(
        publications.first.topics.first.name,
        'Machine Learning Applications',
      );
      expect(publications.first.topics.first.field, 'Computer Science');
      expect(publications.first.topics.first.domain, 'Physical Sciences');

      service.close();
    });

    test('adds the configured API key to list and detail requests', () async {
      final requestedUrls = <Uri>[];
      final service = OpenAlexService(
        apiKey: ' test-api-key ',
        client: MockClient((request) async {
          requestedUrls.add(request.url);
          if (request.url.path.endsWith('/W456')) {
            return http.Response('''
            {
              "id": "https://openalex.org/W456",
              "title": "Authenticated detail request"
            }
            ''', 200);
          }
          return http.Response('''
          {
            "meta": {"count": 0, "next_cursor": null},
            "results": []
          }
          ''', 200);
        }),
      );

      await service.searchTopicPage('machine learning');
      await service.getPublicationDetail('W456');

      expect(requestedUrls, hasLength(2));
      expect(
        requestedUrls.map((uri) => uri.queryParameters['api_key']),
        everyElement('test-api-key'),
      );
      service.close();
    });

    test('never includes the API key in connection error messages', () async {
      const apiKey = 'secret-test-api-key';
      final service = OpenAlexService(
        apiKey: apiKey,
        delay: (_) async {},
        client: MockClient((request) async {
          throw http.ClientException('Network unavailable', request.url);
        }),
      );

      try {
        await service.searchTopicPage('machine learning');
        fail('Expected OpenAlexException.');
      } on OpenAlexException catch (error) {
        expect(error.message, isNot(contains(apiKey)));
        expect(error.message, isNot(contains('api_key')));
        expect(error.message, 'Could not connect to OpenAlex.');
      }

      service.close();
    });

    test(
      'searchTopicPage clamps page size and preserves opaque cursor',
      () async {
        const cursor = 'opaque cursor+/=';
        final service = OpenAlexService(
          client: MockClient((request) async {
            expect(request.url.queryParameters['per_page'], '100');
            expect(request.url.queryParameters['cursor'], cursor);
            return http.Response('''
          {
            "meta": {"count": 0, "next_cursor": null},
            "results": []
          }
          ''', 200);
          }),
        );

        final page = await service.searchTopicPage(
          'ai',
          perPage: 999,
          cursor: cursor,
        );

        expect(page.items, isEmpty);
        expect(page.totalCount, 0);
        expect(page.nextCursor, isNull);

        service.close();
      },
    );

    test('searchTopicPage rejects missing pagination metadata', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response('{"results": []}', 200),
        ),
      );

      await expectLater(
        service.searchTopicPage('ai'),
        throwsA(isA<OpenAlexException>()),
      );

      service.close();
    });

    test('searchTopicPage rejects malformed pagination cursors', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response('''
          {
            "meta": {"count": 1, "next_cursor": 42},
            "results": []
          }
          ''', 200),
        ),
      );

      await expectLater(
        service.searchTopicPage('ai'),
        throwsA(
          isA<OpenAlexException>().having(
            (error) => error.message,
            'message',
            contains('invalid pagination cursor'),
          ),
        ),
      );

      service.close();
    });

    test('searchTopic throws OpenAlexException for server errors', () async {
      var attempts = 0;
      final service = OpenAlexService(
        client: MockClient((request) async {
          attempts += 1;
          return http.Response('Internal Server Error', 500);
        }),
        delay: (_) async {},
      );

      await expectLater(
        service.searchTopic('ai'),
        throwsA(isA<OpenAlexException>()),
      );
      expect(attempts, 3);

      service.close();
    });

    test('non-retryable client errors fail after one request', () async {
      var attempts = 0;
      final service = OpenAlexService(
        client: MockClient((request) async {
          attempts += 1;
          return http.Response('Bad Request', 400);
        }),
        delay: (_) async {},
      );

      await expectLater(
        service.searchTopic('ai'),
        throwsA(isA<OpenAlexException>()),
      );
      expect(attempts, 1);

      service.close();
    });

    test('retryable 429 succeeds on the next request', () async {
      var attempts = 0;
      final service = OpenAlexService(
        client: MockClient((request) async {
          attempts += 1;
          if (attempts == 1) return http.Response('Rate limited', 429);
          return http.Response('''
          {
            "meta": {"count": 0, "next_cursor": null},
            "results": []
          }
          ''', 200);
        }),
        delay: (_) async {},
      );

      final page = await service.searchTopicPage('ai');

      expect(page.items, isEmpty);
      expect(attempts, 2);
      service.close();
    });

    test('searchTopic rejects empty keywords', () async {
      final service = OpenAlexService(
        client: MockClient((request) async => http.Response('{}', 200)),
      );

      await expectLater(
        service.searchTopic('  '),
        throwsA(isA<OpenAlexException>()),
      );

      service.close();
    });

    test('getPublicationDetail parses one OpenAlex work by id', () async {
      final service = OpenAlexService(
        client: MockClient((request) async {
          expect(request.url.path, '/works/W456');

          return http.Response('''
          {
            "id": "https://openalex.org/W456",
            "display_name": "Detail View for Scholarly Articles",
            "publication_year": 2023,
            "cited_by_count": 88,
            "primary_location": {
              "source": {
                "display_name": "Mobile Research Journal"
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
          ''', 200);
        }),
      );

      final publication = await service.getPublicationDetail(
        'https://openalex.org/W456',
      );

      expect(publication.id, 'https://openalex.org/W456');
      expect(publication.title, 'Detail View for Scholarly Articles');
      expect(publication.publicationYear, 2023);
      expect(publication.citationCount, 88);
      expect(publication.journalName, 'Mobile Research Journal');
      expect(publication.authors, ['Mai Vo']);

      service.close();
    });

    test('getPublicationDetail rejects empty ids', () async {
      final service = OpenAlexService(
        client: MockClient((request) async => http.Response('{}', 200)),
      );

      await expectLater(
        service.getPublicationDetail(' '),
        throwsA(isA<OpenAlexException>()),
      );

      service.close();
    });

    test('getWorksByAuthor filters OpenAlex works by author id', () async {
      final service = OpenAlexService(
        client: MockClient((request) async {
          expect(
            request.url.queryParameters['filter'],
            'authorships.author.id:A123',
          );
          expect(request.url.queryParameters['sort'], 'cited_by_count:desc');
          expect(request.url.queryParameters['per_page'], '20');

          return http.Response('''
          {
            "results": [
              {
                "id": "https://openalex.org/W789",
                "title": "Author Focused Research",
                "publication_year": 2024,
                "cited_by_count": 12,
                "authorships": [
                  {
                    "author": {
                      "id": "https://openalex.org/A123",
                      "display_name": "Linh Nguyen"
                    }
                  }
                ]
              }
            ]
          }
          ''', 200);
        }),
      );

      final publications = await service.getWorksByAuthor(
        'https://openalex.org/A123',
      );

      expect(publications, hasLength(1));
      expect(publications.first.title, 'Author Focused Research');
      expect(
        publications.first.authorIdsByName['Linh Nguyen'],
        'https://openalex.org/A123',
      );

      service.close();
    });

    test('getWorksByJournal filters OpenAlex works by source id', () async {
      final service = OpenAlexService(
        client: MockClient((request) async {
          expect(
            request.url.queryParameters['filter'],
            'primary_location.source.id:S123',
          );
          expect(request.url.queryParameters['per_page'], '20');

          return http.Response('''
          {
            "results": [
              {
                "id": "https://openalex.org/W790",
                "title": "Journal Focused Research",
                "publication_year": 2023,
                "cited_by_count": 31,
                "primary_location": {
                  "source": {
                    "id": "https://openalex.org/S123",
                    "display_name": "Journal of Data Science"
                  }
                }
              }
            ]
          }
          ''', 200);
        }),
      );

      final publications = await service.getWorksByJournal(
        'https://openalex.org/S123',
      );

      expect(publications, hasLength(1));
      expect(publications.first.journalName, 'Journal of Data Science');
      expect(publications.first.journalId, 'https://openalex.org/S123');

      service.close();
    });
  });
}
