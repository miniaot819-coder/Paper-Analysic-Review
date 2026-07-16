import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/services/pdf_report_service.dart';

void main() {
  test('creates a readable multi-section PDF document', () async {
    const service = PdfReportService();

    final bytes = await service.generate(
      topic: 'Artificial Intelligence',
      publications: _publications,
      generatedAt: DateTime.utc(2026, 7, 14, 8, 30),
    );

    expect(bytes.length, greaterThan(1500));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(String.fromCharCodes(bytes.skip(bytes.length - 6)), contains('EOF'));
  });

  test('refuses to generate a report without publications', () async {
    const service = PdfReportService();

    expect(
      () => service.generate(
        topic: 'AI',
        publications: const [],
        generatedAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
  });

  test('normalizes Vietnamese report text for the built-in PDF font', () {
    expect(
      pdfSafeText('Trí tuệ nhân tạo – Đổi mới'),
      'Tri tue nhan tao - Doi moi',
    );
  });
}

const _publications = <Publication>[
  Publication(
    id: 'W1',
    title: 'Artificial Intelligence in Healthcare',
    publicationYear: 2024,
    citationCount: 20,
    journalName: 'Journal of AI',
    authors: ['Alice', 'Bob'],
  ),
  Publication(
    id: 'W2',
    title: 'Machine Learning Research',
    publicationYear: 2025,
    citationCount: 10,
    journalName: 'Computing Review',
    authors: ['Alice'],
  ),
  Publication(
    id: 'W3',
    title: 'Responsible AI',
    publicationYear: 2025,
    citationCount: 30,
    journalName: 'Journal of AI',
    authors: ['Carol'],
  ),
];
