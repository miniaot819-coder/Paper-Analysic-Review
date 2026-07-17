import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/publication.dart';
import '../models/ranked_item.dart';
import '../models/trend_data.dart';
import 'analytics_service.dart';

abstract interface class ReportPdfGenerator {
  Future<Uint8List> generate({
    required String topic,
    required List<Publication> publications,
    required DateTime generatedAt,
  });
}

class PdfReportService implements ReportPdfGenerator {
  const PdfReportService({
    AnalyticsService analytics = const AnalyticsService(),
  }) : _analytics = analytics;

  final AnalyticsService _analytics;

  @override
  Future<Uint8List> generate({
    required String topic,
    required List<Publication> publications,
    required DateTime generatedAt,
  }) async {
    if (publications.isEmpty) {
      throw ArgumentError.value(
        publications,
        'publications',
        'At least one publication is required.',
      );
    }

    final dashboard = _analytics.generateDashboardData(publications);
    final trend = _analytics.getPublicationTrendByYear(publications);
    final topJournals = _analytics.getTopJournals(publications, limit: 10);
    final topAuthors = _analytics.getTopAuthors(publications, limit: 10);
    final influential = [...publications]
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));

    final document = pw.Document(
      title: 'Journal Trend Analysis - ${pdfSafeText(topic)}',
      author: 'Journal Trend Analyzer',
      creator: 'Journal Trend Analyzer Flutter App',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 42, 36, 42),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        header: (context) => _header(context, topic),
        footer: _footer,
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Text(
            'Research Analytics Report',
            style: pw.TextStyle(
              color: PdfColors.blue800,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Topic: ${pdfSafeText(topic)}',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Generated: ${_formatDateTime(generatedAt)} | Source: OpenAlex',
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Key metrics'),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric('Publications', dashboard.totalPublications.toString()),
              _metric(
                'Average citations',
                dashboard.averageCitationCount.toStringAsFixed(1),
              ),
              _metric(
                'Most active year',
                dashboard.mostActiveYear == 0
                    ? 'N/A'
                    : dashboard.mostActiveYear.toString(),
              ),
              _metric(
                'Top paper citations',
                dashboard.mostInfluentialPaperCitations.toString(),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Publication trend'),
          _trendChart(trend),
          pw.SizedBox(height: 18),
          _sectionTitle('Top journals'),
          _rankingTable(topJournals, countHeader: 'Publications'),
          pw.SizedBox(height: 18),
          _sectionTitle('Top contributing authors'),
          _rankingTable(topAuthors, countHeader: 'Publications'),
          pw.NewPage(),
          _sectionTitle('Most influential publications'),
          _publicationTable(influential.take(10).toList()),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'This report analyzes a sample of ${publications.length} OpenAlex works. '
              'Metrics reflect the retrieved sample and may differ from the complete OpenAlex corpus.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(pw.Context context, String topic) {
    if (context.pageNumber == 1) return pw.SizedBox();
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Journal Trend Analyzer',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            pdfSafeText(topic),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.blue800,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _metric(String label, String value) {
    return pw.Container(
      width: 121,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _trendChart(List<TrendData> trend) {
    if (trend.isEmpty) return pw.Text('No publication trend data available.');
    final maximum = trend
        .map((item) => item.publicationCount)
        .reduce((a, b) => a > b ? a : b);

    return pw.Column(
      children: trend.map((item) {
        final fraction = maximum == 0 ? 0.0 : item.publicationCount / maximum;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 34,
                child: pw.Text(
                  item.year.toString(),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.SizedBox(
                width: 420,
                height: 10,
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 420 * fraction,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue600,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                    pw.Container(
                      width: 420 * (1 - fraction),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 24,
                child: pw.Text(
                  item.publicationCount.toString(),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _rankingTable(
    List<RankedItem> items, {
    required String countHeader,
  }) {
    if (items.isEmpty) return pw.Text('No ranking data available.');
    return pw.TableHelper.fromTextArray(
      headers: ['Rank', 'Name', countHeader],
      data: [
        for (var index = 0; index < items.length; index++)
          [
            '${index + 1}',
            pdfSafeText(items[index].name),
            items[index].count.toString(),
          ],
      ],
      columnWidths: const {
        0: pw.FixedColumnWidth(36),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(64),
      },
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  pw.Widget _publicationTable(List<Publication> publications) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Title', 'Year', 'Journal', 'Citations'],
      data: publications
          .map(
            (item) => [
              pdfSafeText(item.title),
              item.publicationYear.toString(),
              pdfSafeText(item.journalName),
              item.citationCount.toString(),
            ],
          )
          .toList(),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FixedColumnWidth(38),
        2: pw.FlexColumnWidth(2),
        3: pw.FixedColumnWidth(48),
      },
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

String pdfSafeText(String value) {
  const punctuation = <String, String>{
    '\u2013': '-',
    '\u2014': '-',
    '\u2018': "'",
    '\u2019': "'",
    '\u201c': '"',
    '\u201d': '"',
    '\u2026': '...',
  };
  const vietnameseGroups = <String, String>{
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'A': 'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ',
    'e': 'èéẹẻẽêềếệểễ',
    'E': 'ÈÉẸẺẼÊỀẾỆỂỄ',
    'i': 'ìíịỉĩ',
    'I': 'ÌÍỊỈĨ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'O': 'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ',
    'u': 'ùúụủũưừứựửữ',
    'U': 'ÙÚỤỦŨƯỪỨỰỬỮ',
    'y': 'ỳýỵỷỹ',
    'Y': 'ỲÝỴỶỸ',
    'd': 'đ',
    'D': 'Đ',
  };

  var result = value;
  punctuation.forEach((source, target) {
    result = result.replaceAll(source, target);
  });
  vietnameseGroups.forEach((replacement, characters) {
    for (final character in characters.split('')) {
      result = result.replaceAll(character, replacement);
    }
  });
  return result.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
}
