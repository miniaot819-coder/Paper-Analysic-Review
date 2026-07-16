import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/firebase/storage_service.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/services/pdf_report_service.dart';
import 'package:journal_trend_analysis/viewmodels/report_export_view_model.dart';

void main() {
  test(
    'generates, uploads, reports progress, and logs successful export',
    () async {
      final generator = _FakePdfGenerator();
      final uploader = _FakeUploader();
      final loggedTopics = <String>[];
      final viewModel = ReportExportViewModel(
        pdfGenerator: generator,
        uploader: uploader,
        logExport: (topic) async => loggedTopics.add(topic),
        clock: () => DateTime.utc(2026, 7, 14, 8, 30),
      );

      await viewModel.export(
        userId: 'user-123',
        topic: 'Artificial Intelligence',
        publications: _publications,
      );

      expect(viewModel.status, ReportExportStatus.success);
      expect(viewModel.progress, 1);
      expect(viewModel.downloadUrl, 'https://example.test/report.pdf');
      expect(generator.generateCalls, 1);
      expect(uploader.userId, 'user-123');
      expect(
        uploader.fileName,
        'journal_trend_artificial_intelligence_1784017800000.pdf',
      );
      expect(uploader.bytes, Uint8List.fromList([37, 80, 68, 70]));
      expect(uploader.timeout, defaultReportUploadTimeout);
      expect(loggedTopics, ['Artificial Intelligence']);
    },
  );

  test('rejects export without user or publications', () async {
    final viewModel = ReportExportViewModel(
      pdfGenerator: _FakePdfGenerator(),
      uploader: _FakeUploader(),
      logExport: (_) async {},
    );

    await viewModel.export(
      userId: null,
      topic: 'AI',
      publications: _publications,
    );
    expect(viewModel.status, ReportExportStatus.failure);
    expect(viewModel.errorMessage, contains('sign in'));
    expect(viewModel.canRetry, isFalse);

    await viewModel.export(
      userId: 'user-123',
      topic: 'AI',
      publications: const [],
    );
    expect(viewModel.status, ReportExportStatus.failure);
    expect(viewModel.errorMessage, contains('Home'));
    expect(viewModel.canRetry, isFalse);
  });

  test('retains the last request and retries after upload failure', () async {
    final uploader = _FakeUploader(failuresBeforeSuccess: 1);
    final viewModel = ReportExportViewModel(
      pdfGenerator: _FakePdfGenerator(),
      uploader: uploader,
      logExport: (_) async {},
    );

    await viewModel.export(
      userId: 'user-123',
      topic: 'AI',
      publications: _publications,
    );
    expect(viewModel.status, ReportExportStatus.failure);
    expect(viewModel.canRetry, isTrue);

    await viewModel.retry();
    expect(viewModel.status, ReportExportStatus.success);
    expect(uploader.uploadCalls, 2);
  });

  test(
    'ignores a duplicate export while PDF generation is in progress',
    () async {
      final generator = _ControlledPdfGenerator();
      final uploader = _FakeUploader();
      final viewModel = ReportExportViewModel(
        pdfGenerator: generator,
        uploader: uploader,
        logExport: (_) async {},
      );

      final firstExport = viewModel.export(
        userId: 'user-123',
        topic: 'AI',
        publications: _publications,
      );
      expect(viewModel.status, ReportExportStatus.generating);

      await viewModel.export(
        userId: 'user-123',
        topic: 'Duplicate',
        publications: _publications,
      );
      expect(generator.generateCalls, 1);

      generator.complete();
      await firstExport;
      expect(viewModel.status, ReportExportStatus.success);
      expect(uploader.uploadCalls, 1);
    },
  );

  test('dispose during generation stops the remaining export flow', () async {
    final generator = _ControlledPdfGenerator();
    final uploader = _FakeUploader();
    final viewModel = ReportExportViewModel(
      pdfGenerator: generator,
      uploader: uploader,
      logExport: (_) async {},
    );

    final export = viewModel.export(
      userId: 'user-123',
      topic: 'AI',
      publications: _publications,
    );
    expect(viewModel.status, ReportExportStatus.generating);

    viewModel.dispose();
    generator.complete();

    await expectLater(export, completes);
    expect(uploader.uploadCalls, 0);
  });

  test('cancel stops an active upload and never logs export_pdf', () async {
    final uploader = _ControlledUploader();
    final loggedTopics = <String>[];
    final viewModel = ReportExportViewModel(
      pdfGenerator: _FakePdfGenerator(),
      uploader: uploader,
      logExport: (topic) async => loggedTopics.add(topic),
    );

    final export = viewModel.export(
      userId: 'user-123',
      topic: 'AI',
      publications: _publications,
    );
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.status, ReportExportStatus.uploading);

    await viewModel.cancel();
    await expectLater(export, completes);

    expect(viewModel.status, ReportExportStatus.cancelled);
    expect(viewModel.errorMessage, 'Report export canceled.');
    expect(viewModel.canRetry, isTrue);
    expect(uploader.operation.cancelCalls, 1);
    expect(loggedTopics, isEmpty);
  });

  test('dispose cancels an active Firebase Storage upload', () async {
    final uploader = _ControlledUploader();
    final viewModel = ReportExportViewModel(
      pdfGenerator: _FakePdfGenerator(),
      uploader: uploader,
      logExport: (_) async {},
    );

    final export = viewModel.export(
      userId: 'user-123',
      topic: 'AI',
      publications: _publications,
    );
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.status, ReportExportStatus.uploading);

    viewModel.dispose();
    await expectLater(export, completes);

    expect(uploader.operation.cancelCalls, 1);
  });

  test('shows a retryable timeout message and does not log export', () async {
    final uploader = _FakeUploader(
      error: const ReportUploadTimeoutException(Duration(seconds: 2)),
    );
    final loggedTopics = <String>[];
    final viewModel = ReportExportViewModel(
      pdfGenerator: _FakePdfGenerator(),
      uploader: uploader,
      logExport: (topic) async => loggedTopics.add(topic),
      uploadTimeout: const Duration(seconds: 2),
    );

    await viewModel.export(
      userId: 'user-123',
      topic: 'AI',
      publications: _publications,
    );

    expect(viewModel.status, ReportExportStatus.failure);
    expect(viewModel.errorMessage, contains('took too long'));
    expect(viewModel.canRetry, isTrue);
    expect(uploader.timeout, const Duration(seconds: 2));
    expect(loggedTopics, isEmpty);
  });
}

class _FakePdfGenerator implements ReportPdfGenerator {
  int generateCalls = 0;

  @override
  Future<Uint8List> generate({
    required String topic,
    required List<Publication> publications,
    required DateTime generatedAt,
  }) async {
    generateCalls += 1;
    return Uint8List.fromList([37, 80, 68, 70]);
  }
}

class _FakeUploader implements ReportUploader {
  _FakeUploader({this.failuresBeforeSuccess = 0, this.error});

  int failuresBeforeSuccess;
  final Object? error;
  int uploadCalls = 0;
  String? userId;
  String? fileName;
  Uint8List? bytes;
  Duration? timeout;

  @override
  ReportUpload startUploadReport({
    required String userId,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    Duration timeout = defaultReportUploadTimeout,
  }) {
    uploadCalls += 1;
    this.userId = userId;
    this.fileName = fileName;
    this.bytes = bytes;
    this.timeout = timeout;
    onProgress?.call(0.5);
    if (error != null) {
      return _FakeReportUpload(Future<String>.error(error!));
    }
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      return _FakeReportUpload(
        Future<String>.error(StateError('simulated upload failure')),
      );
    }
    onProgress?.call(1);
    return _FakeReportUpload(
      Future<String>.value('https://example.test/report.pdf'),
    );
  }
}

class _FakeReportUpload implements ReportUpload {
  _FakeReportUpload(this.result);

  @override
  final Future<String> result;

  @override
  Future<bool> cancel() async => true;
}

class _ControlledUploader implements ReportUploader {
  final _ControlledReportUpload operation = _ControlledReportUpload();

  @override
  ReportUpload startUploadReport({
    required String userId,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    Duration timeout = defaultReportUploadTimeout,
  }) {
    onProgress?.call(0.25);
    return operation;
  }
}

class _ControlledReportUpload implements ReportUpload {
  final Completer<String> _completer = Completer<String>();
  int cancelCalls = 0;

  @override
  Future<String> get result => _completer.future;

  @override
  Future<bool> cancel() async {
    cancelCalls += 1;
    if (!_completer.isCompleted) {
      _completer.completeError(StateError('simulated cancellation'));
    }
    return true;
  }
}

class _ControlledPdfGenerator implements ReportPdfGenerator {
  final Completer<Uint8List> _completer = Completer<Uint8List>();
  int generateCalls = 0;

  @override
  Future<Uint8List> generate({
    required String topic,
    required List<Publication> publications,
    required DateTime generatedAt,
  }) {
    generateCalls += 1;
    return _completer.future;
  }

  void complete() {
    _completer.complete(Uint8List.fromList([37, 80, 68, 70]));
  }
}

const _publications = <Publication>[
  Publication(
    id: 'W1',
    title: 'AI Research',
    publicationYear: 2026,
    citationCount: 12,
    journalName: 'Journal A',
    authors: ['Alice'],
  ),
];
