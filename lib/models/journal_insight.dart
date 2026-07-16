import 'publication.dart';

class JournalInsight {
  const JournalInsight({
    required this.name,
    required this.publications,
    this.id,
  });

  final String name;
  final String? id;
  final List<Publication> publications;

  int get publicationCount => publications.length;
  int get totalCitations => publications.fold<int>(
    0,
    (sum, publication) => sum + publication.citationCount,
  );
  double get averageCitations =>
      publications.isEmpty ? 0 : totalCitations / publications.length;
}
