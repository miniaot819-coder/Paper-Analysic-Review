import '../models/journal_insight.dart';
import '../models/publication.dart';

class JournalDetailViewModel {
  JournalDetailViewModel(this.journal)
    : publications = List<Publication>.unmodifiable(
        [...journal.publications]
          ..sort((a, b) => b.citationCount.compareTo(a.citationCount)),
      );

  final JournalInsight journal;
  final List<Publication> publications;

  String get name => journal.name;
  int get publicationCount => journal.publicationCount;
  int get totalCitations => journal.totalCitations;
  double get averageCitations => journal.averageCitations;
}
