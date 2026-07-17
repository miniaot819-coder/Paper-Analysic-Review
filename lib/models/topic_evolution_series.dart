import 'year_metric.dart';

class TopicEvolutionSeries {
  const TopicEvolutionSeries({required this.name, required this.points});

  final String name;
  final List<YearMetric> points;
}
