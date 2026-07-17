import 'publication.dart';
import 'trend_data.dart';

class KeywordInsight {
  const KeywordInsight({
    required this.name,
    required this.publications,
    required this.trend,
    required this.growth,
  });

  final String name;
  final List<Publication> publications;
  final List<TrendData> trend;
  final int growth;

  int get frequency => publications.length;
  int get totalCitations => publications.fold<int>(
    0,
    (sum, publication) => sum + publication.citationCount,
  );
}
