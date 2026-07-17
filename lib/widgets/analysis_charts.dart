import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ranked_item.dart';
import '../models/research_frontier_point.dart';
import '../models/author_impact.dart';
import '../models/journal_topic_matrix.dart';
import '../models/landscape_item.dart';
import '../models/trend_data.dart';
import '../models/topic_evolution_series.dart';
import '../models/year_metric.dart';

const _accent = Color(0xFF2B6DE9);
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _track = Color(0xFFE8EEF9);

class PublicationLineChart extends StatelessWidget {
  const PublicationLineChart({super.key, required this.data});

  final List<TrendData> data;

  @override
  Widget build(BuildContext context) {
    final visible = data.where((item) => item.year > 0).toList();
    if (visible.isEmpty) {
      return const ChartEmpty(message: 'No yearly publication data available.');
    }

    return Semantics(
      label: 'Line chart of publication count by year',
      child: SizedBox(
        height: 220,
        child: CustomPaint(
          painter: _LineChartPainter(
            data: visible,
            labelStyle: Theme.of(context).textTheme.labelSmall,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class CitationLineChart extends StatelessWidget {
  const CitationLineChart({super.key, required this.data});

  final List<YearMetric> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const ChartEmpty(message: 'No yearly citation data available.');
    }

    return Semantics(
      label: 'Line chart of total citations by year',
      child: SizedBox(
        height: 220,
        child: CustomPaint(
          painter: _YearMetricLinePainter(
            data: data,
            labelStyle: Theme.of(context).textTheme.labelSmall,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class TopicEvolutionAreaChart extends StatelessWidget {
  const TopicEvolutionAreaChart({super.key, required this.series});

  final List<TopicEvolutionSeries> series;

  @override
  Widget build(BuildContext context) {
    final visibleSeries = series
        .where((item) => item.points.isNotEmpty)
        .toList(growable: false);
    if (visibleSeries.isEmpty) {
      return const ChartEmpty(message: 'No yearly topic data available.');
    }

    const colors = [Color(0xFF2B6DE9), Color(0xFF668EDB), Color(0xFF9DB5E2)];
    return Semantics(
      label: 'Area chart of topic changes over time',
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: CustomPaint(
              painter: _TopicAreaPainter(series: visibleSeries, colors: colors),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: List.generate(visibleSeries.length, (index) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      visibleSeries[index].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class ResearchFrontierBubbleChart extends StatelessWidget {
  const ResearchFrontierBubbleChart({super.key, required this.data});

  final List<ResearchFrontierPoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const ChartEmpty(
        message: 'Not enough yearly data to identify emerging keywords.',
      );
    }

    return Semantics(
      label: 'Bubble chart of emerging topics by keyword and time',
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _ResearchFrontierBubblePainter(data: data),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 8,
            children: const [
              _ChartKey(label: 'X: year', size: 7),
              _ChartKey(label: 'Y: growth', size: 9),
              _ChartKey(label: 'Bubble: publications', size: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartKey extends StatelessWidget {
  const _ChartKey({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class CitationColumnChart extends StatelessWidget {
  const CitationColumnChart({super.key, required this.data});

  final List<YearMetric> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const ChartEmpty(message: 'No yearly citation data available.');
    }

    final visible = data.length > 8 ? data.sublist(data.length - 8) : data;
    final maxValue = visible.fold<int>(
      1,
      (current, item) => math.max(current, item.value),
    );

    return Semantics(
      label: 'Column chart of total citations by year',
      child: SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: visible.map((item) {
            final ratio = item.value / maxValue;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _compactNumber(item.value),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: math.max(0.06, ratio),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.year.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class RankedHorizontalBarChart extends StatelessWidget {
  const RankedHorizontalBarChart({
    super.key,
    required this.data,
    this.semanticLabel = 'Ranked horizontal bar chart',
    this.unit = 'publications',
  });

  final List<RankedItem> data;
  final String semanticLabel;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const ChartEmpty(message: 'No author data available.');
    }

    final maxValue = data.fold<int>(
      1,
      (current, item) => math.max(current, item.count),
    );

    return Semantics(
      label: semanticLabel,
      child: Column(
        children: data.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.count} $unit',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * (item.count / maxValue),
                        height: 9,
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ResearchTreemap extends StatelessWidget {
  const ResearchTreemap({super.key, required this.data});

  final List<LandscapeItem> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const ChartEmpty(message: 'No research field data available.');
    }

    return Semantics(
      label: 'Treemap of research distribution by field',
      child: SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _TreemapPainter(data: data),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class AuthorImpactScatterChart extends StatelessWidget {
  const AuthorImpactScatterChart({super.key, required this.data});

  final List<AuthorImpact> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const ChartEmpty(message: 'No author data available.');
    }

    return Semantics(
      label: 'Scatter plot of author productivity and impact',
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: CustomPaint(
              painter: _ScatterPainter(data: data),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Horizontal axis: publications   Vertical axis: citations',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: _muted),
          ),
        ],
      ),
    );
  }
}

class JournalTopicHeatmap extends StatelessWidget {
  const JournalTopicHeatmap({super.key, required this.matrix});

  final JournalTopicMatrix matrix;

  @override
  Widget build(BuildContext context) {
    if (matrix.isEmpty) {
      return const ChartEmpty(message: 'No journal or topic data available.');
    }

    final maxValue = matrix.values
        .expand((row) => row)
        .fold<int>(1, (current, value) => math.max(current, value));

    return Semantics(
      label: 'Heatmap of topic concentration by journal',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 128),
                for (final topic in matrix.topics)
                  SizedBox(
                    width: 62,
                    child: Tooltip(
                      message: topic,
                      child: Text(
                        topic,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _muted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (var row = 0; row < matrix.journals.length; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 128,
                      child: Text(
                        matrix.journals[row],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (
                      var column = 0;
                      column < matrix.topics.length;
                      column++
                    )
                      Tooltip(
                        message:
                            '${matrix.journals[row]}: ${matrix.topics[column]} (${matrix.values[row][column]} publications)',
                        child: Container(
                          width: 57,
                          height: 42,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0xFFEAF0FA),
                              _accent,
                              matrix.values[row][column] / maxValue,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            matrix.values[row][column].toString(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color:
                                      matrix.values[row][column] / maxValue >
                                          0.5
                                      ? Colors.white
                                      : _ink,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class JournalDonutChart extends StatelessWidget {
  const JournalDonutChart({super.key, required this.data});

  final List<RankedItem> data;

  static const _segmentColors = [
    Color(0xFF2B6DE9),
    Color(0xFF5F87DD),
    Color(0xFF91ACE3),
    Color(0xFFC3D2EC),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const ChartEmpty(message: 'No journal data available.');
    }

    final total = data.fold<int>(0, (sum, item) => sum + item.count);

    return Semantics(
      label: 'Donut chart of leading journal distribution',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final chart = SizedBox(
            width: compact ? 150 : 176,
            height: compact ? 150 : 176,
            child: CustomPaint(
              painter: _DonutChartPainter(
                values: data.map((item) => item.count).toList(),
                colors: _segmentColors,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total.toString(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: _ink, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'publications',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: _muted),
                    ),
                  ],
                ),
              ),
            ),
          );

          final legend = Column(
            children: List.generate(data.length, (index) {
              final item = data[index];
              final percentage = total == 0 ? 0 : item.count / total * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _segmentColors[index % _segmentColors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );

          if (compact) {
            return Column(
              children: [chart, const SizedBox(height: 20), legend],
            );
          }

          return Row(
            children: [
              chart,
              const SizedBox(width: 24),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}

class QuartileDonutChart extends StatelessWidget {
  const QuartileDonutChart({super.key, required this.data});

  final List<RankedItem> data;

  static const _colors = [
    Color(0xFF245FCB),
    Color(0xFF5F87DD),
    Color(0xFF91ACE3),
    Color(0xFFC7D5ED),
  ];

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, item) => sum + item.count);
    if (data.isEmpty || total == 0) {
      return const ChartEmpty(
        message: 'Not enough journal data to calculate quartiles.',
      );
    }

    return Semantics(
      label: 'Donut chart of journal quartiles Q1 through Q4',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final donut = SizedBox(
            width: 168,
            height: 168,
            child: CustomPaint(
              painter: _DonutChartPainter(
                values: data.map((item) => item.count).toList(),
                colors: _colors,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total.toString(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: _ink, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'publications',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: _muted),
                    ),
                  ],
                ),
              ),
            ),
          );

          final legend = Column(
            children: List.generate(data.length, (index) {
              final item = data[index];
              final percentage = item.count / total * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _colors[index % _colors.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${item.count}  (${percentage.toStringAsFixed(0)}%)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );

          if (compact) {
            return Column(
              children: [donut, const SizedBox(height: 18), legend],
            );
          }
          return Row(
            children: [
              donut,
              const SizedBox(width: 26),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}

class ChartEmpty extends StatelessWidget {
  const ChartEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _muted),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.data, required this.labelStyle});

  final List<TrendData> data;
  final TextStyle? labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const top = 16.0;
    const right = 10.0;
    const bottom = 30.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final gridPaint = Paint()
      ..color = _track
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = chart.top + chart.height * i / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final maxValue = data.fold<int>(
      1,
      (current, item) => math.max(current, item.publicationCount),
    );
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? chart.center.dx
          : chart.left + chart.width * i / (data.length - 1);
      final y =
          chart.bottom - chart.height * data[i].publicationCount / maxValue;
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final area = Path()..moveTo(points.first.dx, chart.bottom);
      for (final point in points) {
        area.lineTo(point.dx, point.dy);
      }
      area
        ..lineTo(points.last.dx, chart.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x3D2B6DE9), Color(0x052B6DE9)],
          ).createShader(chart),
      );
    }

    final line = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        line.moveTo(points[i].dx, points[i].dy);
      } else {
        line.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = _accent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = _accent;
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 2, Paint()..color = const Color(0xFFF8FAFD));
    }

    _drawText(canvas, '0', Offset(0, chart.bottom - 7));
    _drawText(canvas, maxValue.toString(), const Offset(0, top - 6));
    final labelIndexes = <int>{0, data.length ~/ 2, data.length - 1};
    for (final index in labelIndexes) {
      final painter = TextPainter(
        text: TextSpan(
          text: data[index].year.toString(),
          style: labelStyle?.copyWith(color: _muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(points[index].dx - painter.width / 2, chart.bottom + 9),
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: labelStyle?.copyWith(color: _muted, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.labelStyle != labelStyle;
  }
}

class _YearMetricLinePainter extends CustomPainter {
  const _YearMetricLinePainter({required this.data, required this.labelStyle});

  final List<YearMetric> data;
  final TextStyle? labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0;
    const top = 16.0;
    const right = 10.0;
    const bottom = 30.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final maxValue = data.fold<int>(
      1,
      (current, item) => math.max(current, item.value),
    );
    final gridPaint = Paint()
      ..color = _track
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = chart.top + chart.height * index / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final tickValue = (maxValue * (3 - index) / 3).round();
      final tickLabel = TextPainter(
        text: TextSpan(
          text: _compactNumber(tickValue),
          style: labelStyle?.copyWith(color: _muted, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tickLabel.paint(
        canvas,
        Offset(chart.left - tickLabel.width - 7, y - tickLabel.height / 2),
      );
    }

    final points = List.generate(data.length, (index) {
      final x = data.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (data.length - 1);
      final y = chart.bottom - chart.height * data[index].value / maxValue;
      return Offset(x, y);
    });
    final line = Path();
    for (var index = 0; index < points.length; index++) {
      index == 0
          ? line.moveTo(points[index].dx, points[index].dy)
          : line.lineTo(points[index].dx, points[index].dy);
    }

    if (points.length > 1) {
      final area = Path()..moveTo(points.first.dx, chart.bottom);
      for (final point in points) {
        area.lineTo(point.dx, point.dy);
      }
      area
        ..lineTo(points.last.dx, chart.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x302B6DE9), Color(0x032B6DE9)],
          ).createShader(chart),
      );
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = _accent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = _accent);
      canvas.drawCircle(point, 2, Paint()..color = const Color(0xFFF8FAFD));
    }

    final labelIndexes = <int>{0, data.length ~/ 2, data.length - 1};
    for (final index in labelIndexes) {
      final painter = TextPainter(
        text: TextSpan(
          text: data[index].year.toString(),
          style: labelStyle?.copyWith(color: _muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(points[index].dx - painter.width / 2, chart.bottom + 9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _YearMetricLinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.labelStyle != labelStyle;
  }
}

class _TopicAreaPainter extends CustomPainter {
  const _TopicAreaPainter({required this.series, required this.colors});

  final List<TopicEvolutionSeries> series;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final visibleSeries = series
        .where((item) => item.points.isNotEmpty)
        .toList(growable: false);
    if (visibleSeries.isEmpty || colors.isEmpty) return;

    const left = 30.0;
    const top = 14.0;
    const right = 10.0;
    const bottom = 28.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final maxValue = visibleSeries
        .expand((item) => item.points)
        .fold<int>(1, (current, point) => math.max(current, point.value));
    final gridPaint = Paint()
      ..color = _track
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = chart.top + chart.height * index / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    for (
      var seriesIndex = visibleSeries.length - 1;
      seriesIndex >= 0;
      seriesIndex--
    ) {
      final item = visibleSeries[seriesIndex];
      final points = List.generate(item.points.length, (index) {
        final x = item.points.length == 1
            ? chart.center.dx
            : chart.left + chart.width * index / (item.points.length - 1);
        final y =
            chart.bottom - chart.height * item.points[index].value / maxValue;
        return Offset(x, y);
      });
      final area = Path()..moveTo(points.first.dx, chart.bottom);
      for (final point in points) {
        area.lineTo(point.dx, point.dy);
      }
      area
        ..lineTo(points.last.dx, chart.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..color = colors[seriesIndex % colors.length].withValues(alpha: 0.2),
      );

      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        line.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = colors[seriesIndex % colors.length]
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final years = visibleSeries.first.points;
    final labelIndexes = <int>{0, years.length ~/ 2, years.length - 1};
    for (final index in labelIndexes) {
      final label = TextPainter(
        text: TextSpan(
          text: years[index].year.toString(),
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = years.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (years.length - 1);
      label.paint(canvas, Offset(x - label.width / 2, chart.bottom + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _TopicAreaPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.colors != colors;
  }
}

class _ResearchFrontierBubblePainter extends CustomPainter {
  const _ResearchFrontierBubblePainter({required this.data});

  final List<ResearchFrontierPoint> data;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const top = 18.0;
    const right = 14.0;
    const bottom = 30.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final minYear = data.map((item) => item.year).reduce(math.min);
    final maxYear = data.map((item) => item.year).reduce(math.max);
    final maxGrowth = data.fold<int>(
      1,
      (current, item) => math.max(current, item.growth),
    );
    final maxCount = data.fold<int>(
      1,
      (current, item) => math.max(current, item.count),
    );

    final gridPaint = Paint()
      ..color = _track
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final x = chart.left + chart.width * index / 4;
      final y = chart.top + chart.height * index / 4;
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), gridPaint);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final sorted = [...data]..sort((a, b) => a.count.compareTo(b.count));
    for (final item in sorted) {
      final yearRatio = maxYear == minYear
          ? 0.5
          : (item.year - minYear) / (maxYear - minYear);
      final growthRatio = item.growth / maxGrowth;
      final radius = 6.0 + 10.0 * math.sqrt(item.count / maxCount);
      final center = Offset(
        (chart.left + chart.width * yearRatio).clamp(
          chart.left + radius,
          chart.right - radius,
        ),
        (chart.bottom - chart.height * growthRatio).clamp(
          chart.top + radius,
          chart.bottom - radius,
        ),
      );
      final bubbleColor = Color.lerp(
        const Color(0xFF9CB5E5),
        _accent,
        growthRatio,
      )!;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = bubbleColor.withValues(alpha: 0.34),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = bubbleColor.withValues(alpha: 0.86)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );

      if (data.indexOf(item) < 4) {
        final label = TextPainter(
          text: TextSpan(
            text: item.keyword,
            style: const TextStyle(
              color: _ink,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 86);
        final labelX = math.min(
          chart.right - label.width - 8,
          math.max(chart.left + 8, center.dx - label.width / 2),
        );
        final showBelow = center.dy - radius - label.height - 8 < chart.top;
        final labelY = showBelow
            ? center.dy + radius + 5
            : center.dy - radius - label.height - 5;
        final labelRect = Rect.fromLTWH(
          labelX - 5,
          labelY - 3,
          label.width + 10,
          label.height + 6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
          Paint()..color = const Color(0xFFF8FAFD).withValues(alpha: 0.94),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
          Paint()
            ..color = _track
            ..style = PaintingStyle.stroke,
        );
        label.paint(canvas, Offset(labelX, labelY));
      }
    }

    _paintBubbleLabel(
      canvas,
      minYear.toString(),
      Offset(chart.left, chart.bottom + 9),
    );
    if (maxYear != minYear) {
      final maxYearLabel = _bubbleTextPainter(maxYear.toString());
      maxYearLabel.paint(
        canvas,
        Offset(chart.right - maxYearLabel.width, chart.bottom + 9),
      );
    }
    _paintBubbleLabel(canvas, '+$maxGrowth', const Offset(2, top - 5));
    _paintBubbleLabel(canvas, '0', Offset(14, chart.bottom - 6));
  }

  TextPainter _bubbleTextPainter(String text) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: _muted, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _paintBubbleLabel(Canvas canvas, String text, Offset offset) {
    _bubbleTextPainter(text).paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ResearchFrontierBubblePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.values, required this.colors});

  final List<int> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return;

    final rect = Offset.zero & size;
    final strokeWidth = size.shortestSide * 0.15;
    final arcRect = rect.deflate(strokeWidth / 2 + 2);
    var start = -math.pi / 2;
    const gap = 0.035;

    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(
        arcRect,
        start + gap / 2,
        math.max(0, sweep - gap),
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class _TreemapPainter extends CustomPainter {
  const _TreemapPainter({required this.data});

  final List<LandscapeItem> data;

  static const colors = [
    Color(0xFF245FCB),
    Color(0xFF4778D2),
    Color(0xFF6991D9),
    Color(0xFF85A5DF),
    Color(0xFFA1BAE6),
    Color(0xFFB8CAEA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<int>(0, (sum, item) => sum + item.count);
    if (total == 0) return;

    var remaining = Rect.fromLTWH(0, 0, size.width, size.height);
    var remainingValue = total;
    for (var index = 0; index < data.length; index++) {
      final item = data[index];
      final isLast = index == data.length - 1;
      final ratio = isLast ? 1.0 : item.count / remainingValue;
      final splitVertically = remaining.width >= remaining.height;
      late final Rect cell;

      if (splitVertically) {
        final width = remaining.width * ratio;
        cell = Rect.fromLTWH(
          remaining.left,
          remaining.top,
          width,
          remaining.height,
        );
        remaining = Rect.fromLTWH(
          remaining.left + width,
          remaining.top,
          remaining.width - width,
          remaining.height,
        );
      } else {
        final height = remaining.height * ratio;
        cell = Rect.fromLTWH(
          remaining.left,
          remaining.top,
          remaining.width,
          height,
        );
        remaining = Rect.fromLTWH(
          remaining.left,
          remaining.top + height,
          remaining.width,
          remaining.height - height,
        );
      }
      remainingValue -= item.count;

      final padded = cell.deflate(2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(padded, const Radius.circular(10)),
        Paint()..color = colors[index % colors.length],
      );

      if (padded.width < 58 || padded.height < 38) continue;
      final label = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: item.field,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: '\n${item.domain}  ${item.count}',
              style: const TextStyle(
                color: Color(0xFFEAF0FF),
                fontSize: 9,
                height: 1.5,
              ),
            ),
          ],
        ),
        maxLines: padded.height > 54 ? 3 : 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: padded.width - 16);
      label.paint(canvas, Offset(padded.left + 8, padded.top + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _ScatterPainter extends CustomPainter {
  const _ScatterPainter({required this.data});

  final List<AuthorImpact> data;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const top = 16.0;
    const right = 12.0;
    const bottom = 28.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final gridPaint = Paint()
      ..color = _track
      ..strokeWidth = 1;

    for (var index = 0; index <= 4; index++) {
      final x = chart.left + chart.width * index / 4;
      final y = chart.top + chart.height * index / 4;
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), gridPaint);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final maxPublications = data.fold<int>(
      1,
      (current, item) => math.max(current, item.publicationCount),
    );
    final maxCitations = data.fold<int>(
      1,
      (current, item) => math.max(current, item.citationCount),
    );

    for (var index = 0; index < data.length; index++) {
      final item = data[index];
      final x =
          chart.left + chart.width * item.publicationCount / maxPublications;
      final y = chart.bottom - chart.height * item.citationCount / maxCitations;
      final radius = 5.0 + math.min(5.0, item.publicationCount.toDouble());
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = _accent.withValues(alpha: 0.72),
      );

      if (index < 4) {
        final label = TextPainter(
          text: TextSpan(
            text: item.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 76);
        label.paint(canvas, Offset(x + radius + 3, y - label.height / 2));
      }
    }

    _paintAxisLabel(canvas, '0', Offset(10, chart.bottom - 6));
    _paintAxisLabel(canvas, maxCitations.toString(), const Offset(0, top - 5));
    _paintAxisLabel(
      canvas,
      maxPublications.toString(),
      Offset(chart.right - 8, chart.bottom + 9),
    );
  }

  void _paintAxisLabel(Canvas canvas, String value, Offset offset) {
    final label = TextPainter(
      text: const TextSpan(style: TextStyle(color: _muted, fontSize: 9)),
      textDirection: TextDirection.ltr,
    );
    label.text = TextSpan(
      text: value,
      style: const TextStyle(color: _muted, fontSize: 9),
    );
    label.layout();
    label.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

String _compactNumber(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.toString();
}
