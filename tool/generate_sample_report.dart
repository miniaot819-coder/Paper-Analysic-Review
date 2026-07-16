import 'dart:io';

import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/services/pdf_report_service.dart';

Future<void> main() async {
  const publications = <Publication>[
    Publication(
      id: 'W1',
      title: 'Artificial Intelligence in Healthcare',
      publicationYear: 2024,
      citationCount: 120,
      journalName: 'Journal of AI Research',
      authors: ['Alice Morgan', 'Benjamin Lee'],
    ),
    Publication(
      id: 'W2',
      title: 'Responsible Machine Learning Systems',
      publicationYear: 2025,
      citationCount: 84,
      journalName: 'Computing Review',
      authors: ['Alice Morgan'],
    ),
    Publication(
      id: 'W3',
      title: 'Explainable AI for Clinical Decisions',
      publicationYear: 2025,
      citationCount: 97,
      journalName: 'Journal of AI Research',
      authors: ['Carol Nguyen', 'Benjamin Lee'],
    ),
  ];

  final bytes = await const PdfReportService().generate(
    topic: 'Artificial Intelligence',
    publications: publications,
    generatedAt: DateTime.utc(2026, 7, 15, 14, 30),
  );
  final output = File('output/pdf/journal_trend_report_sample.pdf');
  await output.parent.create(recursive: true);
  await output.writeAsBytes(bytes, flush: true);
  stdout.writeln(output.absolute.path);
}
