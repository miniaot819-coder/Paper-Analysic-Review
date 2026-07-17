import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/openalex_page.dart';
import '../models/publication.dart';

class OpenAlexException implements Exception {
  const OpenAlexException(this.message);

  final String message;

  @override
  String toString() => 'OpenAlexException: $message';
}

class OpenAlexService {
  OpenAlexService({
    http.Client? client,
    Uri? baseUri,
    Future<void> Function(Duration duration)? delay,
    String apiKey = const String.fromEnvironment('OPENALEX_API_KEY'),
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? Uri.https('api.openalex.org', '/works'),
       _delay = delay ?? Future<void>.delayed,
       _apiKey = apiKey.trim();

  final http.Client _client;
  final Uri _baseUri;
  final Future<void> Function(Duration duration) _delay;
  final String _apiKey;

  static const int maxPerPage = 100;
  static const int _maxAttempts = 3;

  static const String _workSelectFields =
      'id,title,publication_year,cited_by_count,doi,'
      'primary_location,authorships,abstract_inverted_index,keywords,topics';

  Future<List<Publication>> searchTopic(
    String keyword, {
    int perPage = 20,
  }) async {
    final page = await searchTopicPage(keyword, perPage: perPage);
    return page.items;
  }

  Future<OpenAlexPage<Publication>> searchTopicPage(
    String keyword, {
    int perPage = maxPerPage,
    String cursor = '*',
  }) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) {
      throw const OpenAlexException('Keyword must not be empty.');
    }
    if (cursor.isEmpty) {
      throw const OpenAlexException('Cursor must not be empty.');
    }

    final uri = _baseUri.replace(
      queryParameters: {
        'search': trimmedKeyword,
        'per_page': perPage.clamp(1, maxPerPage).toString(),
        'cursor': cursor,
        'select': _workSelectFields,
      },
    );

    return _getPublicationPage(uri, requireMeta: true);
  }

  Future<List<Publication>> getWorksByAuthor(
    String authorId, {
    int perPage = 20,
  }) async {
    final id = _openAlexEntityId(authorId);
    if (id.isEmpty) {
      throw const OpenAlexException('Author id must not be empty.');
    }

    final uri = _baseUri.replace(
      queryParameters: {
        'filter': 'authorships.author.id:$id',
        'per_page': perPage.clamp(1, maxPerPage).toString(),
        'sort': 'cited_by_count:desc',
        'select': _workSelectFields,
      },
    );

    return _getPublicationList(uri);
  }

  Future<List<Publication>> getWorksByJournal(
    String journalId, {
    int perPage = 20,
  }) async {
    final id = _openAlexEntityId(journalId);
    if (id.isEmpty) {
      throw const OpenAlexException('Journal id must not be empty.');
    }

    final uri = _baseUri.replace(
      queryParameters: {
        'filter': 'primary_location.source.id:$id',
        'per_page': perPage.clamp(1, maxPerPage).toString(),
        'sort': 'cited_by_count:desc',
        'select': _workSelectFields,
      },
    );

    return _getPublicationList(uri);
  }

  Future<List<Publication>> _getPublicationList(Uri uri) async {
    final page = await _getPublicationPage(uri);
    return page.items;
  }

  Future<OpenAlexPage<Publication>> _getPublicationPage(
    Uri uri, {
    bool requireMeta = false,
  }) async {
    try {
      final response = await _getWithRetry(uri);

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const OpenAlexException('OpenAlex returned invalid JSON.');
      }

      final results = decoded['results'];
      if (results is! List) {
        throw const OpenAlexException('OpenAlex response has no results list.');
      }

      final publications = results
          .whereType<Map<String, dynamic>>()
          .map(Publication.fromOpenAlexJson)
          .toList();

      var totalCount = publications.length;
      String? nextCursor;
      double? costUsd;
      final meta = decoded['meta'];
      if (requireMeta && meta is! Map<String, dynamic>) {
        throw const OpenAlexException(
          'OpenAlex response has no pagination metadata.',
        );
      }
      if (meta is Map<String, dynamic>) {
        final rawCount = meta['count'];
        if (requireMeta && (rawCount is! num || rawCount < 0)) {
          throw const OpenAlexException(
            'OpenAlex response has an invalid total result count.',
          );
        }
        if (rawCount is num && rawCount >= 0) totalCount = rawCount.toInt();

        final rawCursor = meta['next_cursor'];
        if (rawCursor is String && rawCursor.trim().isNotEmpty) {
          nextCursor = rawCursor;
        } else if (requireMeta && rawCursor != null) {
          throw const OpenAlexException(
            'OpenAlex response has an invalid pagination cursor.',
          );
        }

        final rawCost = meta['cost_usd'];
        if (rawCost is num) costUsd = rawCost.toDouble();
      }

      return OpenAlexPage<Publication>(
        items: publications,
        totalCount: totalCount < publications.length
            ? publications.length
            : totalCount,
        nextCursor: nextCursor,
        costUsd: costUsd,
      );
    } on FormatException {
      throw const OpenAlexException('Could not parse OpenAlex response.');
    } on OpenAlexException {
      rethrow;
    } catch (_) {
      throw const OpenAlexException('Could not process the OpenAlex response.');
    }
  }

  Future<Publication> getPublicationDetail(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw const OpenAlexException('Publication id must not be empty.');
    }

    final uri = _workUri(trimmedId);

    try {
      final response = await _getWithRetry(uri);

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const OpenAlexException('OpenAlex returned invalid detail JSON.');
      }

      return Publication.fromOpenAlexJson(decoded);
    } on FormatException {
      throw const OpenAlexException(
        'Could not parse OpenAlex detail response.',
      );
    } on OpenAlexException {
      rethrow;
    } catch (_) {
      throw const OpenAlexException(
        'Could not process the OpenAlex detail response.',
      );
    }
  }

  Uri _workUri(String id) {
    final parsed = Uri.tryParse(id);
    final workId = parsed?.pathSegments.isNotEmpty == true
        ? parsed!.pathSegments.last
        : id;

    return _baseUri.replace(path: '${_baseUri.path}/$workId');
  }

  String _openAlexEntityId(String id) {
    final trimmed = id.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed?.pathSegments.isNotEmpty == true) {
      return parsed!.pathSegments.last;
    }
    return trimmed;
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    final authenticatedUri = _withApiKey(uri);
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final response = await _client
            .get(authenticatedUri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        final successful =
            response.statusCode >= 200 && response.statusCode < 300;
        if (successful) return response;

        final canRetry =
            _isRetryableStatus(response.statusCode) &&
            attempt < _maxAttempts - 1;
        if (!canRetry) {
          throw OpenAlexException(
            'OpenAlex request failed with status ${response.statusCode}.',
          );
        }
      } on TimeoutException {
        if (attempt == _maxAttempts - 1) {
          throw const OpenAlexException('OpenAlex request timed out.');
        }
      } on OpenAlexException {
        rethrow;
      } catch (_) {
        if (attempt == _maxAttempts - 1) {
          throw const OpenAlexException('Could not connect to OpenAlex.');
        }
      }

      await _delay(Duration(seconds: 1 << attempt));
    }

    throw const OpenAlexException('OpenAlex request failed.');
  }

  Uri _withApiKey(Uri uri) {
    if (_apiKey.isEmpty) return uri;
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'api_key': _apiKey},
    );
  }

  bool _isRetryableStatus(int statusCode) {
    return statusCode == 429 || statusCode >= 500;
  }

  void close() {
    _client.close();
  }
}
