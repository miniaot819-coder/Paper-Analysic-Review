import 'dart:async';

import 'package:flutter/foundation.dart';

import '../firebase/analytics_tracking_service.dart';
import '../firebase/storage_service.dart';
import '../models/publication.dart';
import '../services/pdf_report_service.dart';

enum ReportExportStatus {
  idle,
  generating,
  uploading,
  success,
  failure,
  cancelled,
}

class ReportExportViewModel extends ChangeNotifier {
  ReportExportViewModel({
    ReportPdfGenerator? pdfGenerator,
    ReportUploader? uploader,
    Future<void> Function(String topic)? logExport,
    DateTime Function()? clock,
    Duration uploadTimeout = defaultReportUploadTimeout,
  }) : _pdfGenerator = pdfGenerator ?? const PdfReportService(),
       _uploader = uploader ?? StorageService.instance,
       _logExport = logExport ?? AnalyticsTrackingService.instance.logExportPdf,
       _clock = clock ?? DateTime.now,
       _uploadTimeout = uploadTimeout;

  final ReportPdfGenerator _pdfGenerator;
  final ReportUploader _uploader;
  final Future<void> Function(String topic) _logExport;
  final DateTime Function() _clock;
  final Duration _uploadTimeout;

  ReportExportStatus _status = ReportExportStatus.idle;
  double _progress = 0;
  String? _downloadUrl;
  String? _errorMessage;
  String? _lastUserId;
  String? _lastTopic;
  List<Publication> _lastPublications = const [];
  bool _isDisposed = false;
  int _operationVersion = 0;
  ReportUpload? _activeUpload;

  ReportExportStatus get status => _status;
  double get progress => _progress;
  String? get downloadUrl => _downloadUrl;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _status == ReportExportStatus.generating ||
      _status == ReportExportStatus.uploading;
  bool get canRetry =>
      (_status == ReportExportStatus.failure ||
          _status == ReportExportStatus.cancelled) &&
      _lastUserId != null &&
      _lastTopic != null &&
      _lastPublications.isNotEmpty;

  Future<void> export({
    required String? userId,
    required String topic,
    required List<Publication> publications,
  }) async {
    if (_isDisposed || isBusy) return;
    final operationVersion = ++_operationVersion;

    final normalizedUserId = userId?.trim();
    final normalizedTopic = topic.trim();
    _lastUserId = normalizedUserId;
    _lastTopic = normalizedTopic;
    _lastPublications = List<Publication>.unmodifiable(publications);
    _downloadUrl = null;
    _errorMessage = null;

    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      _fail('You must sign in before exporting a report.');
      return;
    }
    if (normalizedTopic.isEmpty || publications.isEmpty) {
      _fail('Search for a topic on Home before exporting a report.');
      return;
    }

    final generatedAt = _clock();
    try {
      _setStatus(ReportExportStatus.generating, progress: 0.05);
      final bytes = await _pdfGenerator.generate(
        topic: normalizedTopic,
        publications: publications,
        generatedAt: generatedAt,
      );
      if (!_isCurrent(operationVersion)) return;

      _setStatus(ReportExportStatus.uploading, progress: 0.1);
      final fileName = _buildFileName(normalizedTopic, generatedAt);
      final upload = _uploader.startUploadReport(
        userId: normalizedUserId,
        fileName: fileName,
        bytes: bytes,
        timeout: _uploadTimeout,
        onProgress: (value) {
          if (!_isCurrent(operationVersion) ||
              _status != ReportExportStatus.uploading) {
            return;
          }
          _progress = 0.1 + (value.clamp(0.0, 1.0) * 0.9);
          notifyListeners();
        },
      );
      _activeUpload = upload;
      final url = await upload.result;
      if (!_isCurrent(operationVersion)) return;

      _downloadUrl = url;
      _setStatus(ReportExportStatus.success, progress: 1);
      try {
        await _logExport(normalizedTopic);
      } catch (_) {
        // Analytics must never turn a successful upload into a failed export.
      }
    } on ReportUploadTimeoutException {
      if (!_isCurrent(operationVersion)) return;
      _fail(
        'The upload took too long and was canceled. Check your connection and try again.',
      );
    } catch (_) {
      if (!_isCurrent(operationVersion)) return;
      _fail(
        'Unable to generate or upload the PDF to Firebase Storage. Please try again.',
      );
    } finally {
      if (_isCurrent(operationVersion)) _activeUpload = null;
    }
  }

  Future<void> retry() async {
    if (_isDisposed || !canRetry) return;
    await export(
      userId: _lastUserId,
      topic: _lastTopic!,
      publications: _lastPublications,
    );
  }

  Future<void> cancel() async {
    if (_isDisposed || !isBusy) return;

    ++_operationVersion;
    final upload = _activeUpload;
    _activeUpload = null;
    _status = ReportExportStatus.cancelled;
    _progress = 0;
    _downloadUrl = null;
    _errorMessage = 'Report export canceled.';
    notifyListeners();

    if (upload != null) {
      await _cancelQuietly(upload);
    }
  }

  bool _isCurrent(int operationVersion) {
    return !_isDisposed && operationVersion == _operationVersion;
  }

  Future<void> _cancelQuietly(ReportUpload upload) async {
    try {
      await upload.cancel();
    } catch (_) {
      // Cancellation is best effort; the stale operation is already ignored.
    }
  }

  void _setStatus(ReportExportStatus value, {required double progress}) {
    if (_isDisposed) return;
    _status = value;
    _progress = progress;
    if (value != ReportExportStatus.failure) _errorMessage = null;
    notifyListeners();
  }

  void _fail(String message) {
    if (_isDisposed) return;
    _status = ReportExportStatus.failure;
    _progress = 0;
    _errorMessage = message;
    notifyListeners();
  }

  String _buildFileName(String topic, DateTime timestamp) {
    final slug = topic
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safeSlug = slug.isEmpty ? 'topic' : slug;
    return 'journal_trend_${safeSlug}_${timestamp.toUtc().millisecondsSinceEpoch}.pdf';
  }

  @override
  void dispose() {
    _isDisposed = true;
    ++_operationVersion;
    final upload = _activeUpload;
    _activeUpload = null;
    if (upload != null) unawaited(_cancelQuietly(upload));
    super.dispose();
  }
}
