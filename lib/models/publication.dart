import 'research_topic.dart';

class Publication {
  const Publication({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.citationCount,
    required this.journalName,
    required this.authors,
    this.keywords = const [],
    this.topics = const [],
    this.journalId,
    this.authorIdsByName = const {},
    this.doi,
    this.abstractText,
  });

  final String id;
  final String title;
  final int publicationYear;
  final int citationCount;
  final String journalName;
  final List<String> authors;
  final List<String> keywords;
  final List<ResearchTopic> topics;
  final String? journalId;
  final Map<String, String> authorIdsByName;
  final String? doi;
  final String? abstractText;

  factory Publication.fromOpenAlexJson(Map<String, dynamic> json) {
    return Publication(
      id: _stringValue(json['id'], fallback: 'unknown-id'),
      title: _stringValue(
        json['title'] ?? json['display_name'],
        fallback: 'Untitled publication',
      ),
      publicationYear: _intValue(json['publication_year']),
      citationCount: _intValue(json['cited_by_count']),
      journalName: _journalName(json),
      journalId: _journalId(json),
      authors: _authors(json['authorships']),
      authorIdsByName: _authorIdsByName(json['authorships']),
      keywords: _keywords(json['keywords']),
      topics: _topics(json['topics']),
      doi: _nullableString(json['doi']),
      abstractText: _abstractFromInvertedIndex(json['abstract_inverted_index']),
    );
  }
}

List<String> _keywords(Object? value) {
  if (value is! List) return const [];

  return value
      .whereType<Map<String, dynamic>>()
      .map((item) => _nullableString(item['display_name']))
      .whereType<String>()
      .toList();
}

List<ResearchTopic> _topics(Object? value) {
  if (value is! List) return const [];

  final topics = <ResearchTopic>[];
  for (final item in value.whereType<Map<String, dynamic>>()) {
    final name = _nullableString(item['display_name']);
    final field = item['field'];
    final domain = item['domain'];
    if (name == null ||
        field is! Map<String, dynamic> ||
        domain is! Map<String, dynamic>) {
      continue;
    }

    final fieldName = _nullableString(field['display_name']);
    final domainName = _nullableString(domain['display_name']);
    if (fieldName == null || domainName == null) continue;

    topics.add(ResearchTopic(name: name, field: fieldName, domain: domainName));
  }
  return topics;
}

String _stringValue(Object? value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

String _journalName(Map<String, dynamic> json) {
  final primaryLocation = json['primary_location'];
  if (primaryLocation is Map<String, dynamic>) {
    final source = primaryLocation['source'];
    if (source is Map<String, dynamic>) {
      return _stringValue(source['display_name'], fallback: 'Unknown Journal');
    }
  }

  final hostVenue = json['host_venue'];
  if (hostVenue is Map<String, dynamic>) {
    return _stringValue(hostVenue['display_name'], fallback: 'Unknown Journal');
  }

  return 'Unknown Journal';
}

String? _journalId(Map<String, dynamic> json) {
  final primaryLocation = json['primary_location'];
  if (primaryLocation is Map<String, dynamic>) {
    final source = primaryLocation['source'];
    if (source is Map<String, dynamic>) {
      return _nullableString(source['id']);
    }
  }

  final hostVenue = json['host_venue'];
  if (hostVenue is Map<String, dynamic>) {
    return _nullableString(hostVenue['id']);
  }

  return null;
}

List<String> _authors(Object? authorships) {
  if (authorships is! List) return const [];

  final authors = <String>[];
  for (final item in authorships) {
    if (item is! Map<String, dynamic>) continue;

    final author = item['author'];
    if (author is! Map<String, dynamic>) continue;

    final name = _nullableString(author['display_name']);
    if (name != null) authors.add(name);
  }

  return authors;
}

Map<String, String> _authorIdsByName(Object? authorships) {
  if (authorships is! List) return const {};

  final authorIds = <String, String>{};
  for (final item in authorships) {
    if (item is! Map<String, dynamic>) continue;

    final author = item['author'];
    if (author is! Map<String, dynamic>) continue;

    final name = _nullableString(author['display_name']);
    final id = _nullableString(author['id']);
    if (name != null && id != null) authorIds[name] = id;
  }

  return authorIds;
}

String? _abstractFromInvertedIndex(Object? value) {
  if (value is! Map<String, dynamic>) return null;

  final wordsByPosition = <int, String>{};
  for (final entry in value.entries) {
    final positions = entry.value;
    if (positions is! List) continue;

    for (final position in positions) {
      if (position is int) {
        wordsByPosition[position] = entry.key;
      }
    }
  }

  if (wordsByPosition.isEmpty) return null;

  final positions = wordsByPosition.keys.toList()..sort();
  return positions.map((position) => wordsByPosition[position]).join(' ');
}
