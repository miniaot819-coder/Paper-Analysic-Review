import '../models/journal_insight.dart';
import '../models/publication.dart';
import 'research_tab_view_model.dart';

class JournalsViewModel extends ResearchTabViewModel {
  JournalsViewModel({
    super.initialTopic = 'Artificial Intelligence',
    super.repository,
  });

  List<Publication>? _cachedPublications;
  List<JournalInsight> _cachedJournals = const [];
  int _cachedTotalCitations = 0;

  List<JournalInsight> get journals {
    final publications = state.publications;
    if (identical(_cachedPublications, publications)) {
      return _cachedJournals;
    }

    final grouped = <String, List<Publication>>{};
    final displayNames = <String, String>{};
    final ids = <String, String>{};

    var totalCitations = 0;
    for (final publication in publications) {
      totalCitations += publication.citationCount;
      final name = publication.journalName.trim();
      if (name.isEmpty || name.toLowerCase().startsWith('unknown')) continue;
      final key = name.toLowerCase();
      displayNames.putIfAbsent(key, () => name);
      grouped.putIfAbsent(key, () => []).add(publication);
      final id = publication.journalId?.trim();
      if (id != null && id.isNotEmpty) ids.putIfAbsent(key, () => id);
    }

    final result =
        grouped.entries
            .map(
              (entry) => JournalInsight(
                name: displayNames[entry.key]!,
                id: ids[entry.key],
                publications: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) {
            final byPublications = b.publicationCount.compareTo(
              a.publicationCount,
            );
            if (byPublications != 0) return byPublications;
            final byCitations = b.totalCitations.compareTo(a.totalCitations);
            return byCitations != 0 ? byCitations : a.name.compareTo(b.name);
          });
    _cachedPublications = publications;
    _cachedJournals = List<JournalInsight>.unmodifiable(result);
    _cachedTotalCitations = totalCitations;
    return _cachedJournals;
  }

  int get totalCitations {
    journals;
    return _cachedTotalCitations;
  }
}
