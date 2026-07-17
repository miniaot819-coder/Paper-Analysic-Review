import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

const defaultReportUploadTimeout = Duration(seconds: 60);

class ReportUploadTimeoutException implements Exception {
  const ReportUploadTimeoutException(this.timeout);

  final Duration timeout;

  @override
  String toString() => 'Report upload timed out after ${timeout.inSeconds}s.';
}

abstract interface class ReportUpload {
  Future<String> get result;

  Future<bool> cancel();
}

abstract interface class ReportUploader {
  ReportUpload startUploadReport({
    required String userId,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    Duration timeout = defaultReportUploadTimeout,
  });
}

class StorageService implements ReportUploader {
  StorageService._();

  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Reference reportReference({
    required String userId,
    required String fileName,
  }) {
    return _storage.ref('reports/$userId/$fileName');
  }

  @override
  ReportUpload startUploadReport({
    required String userId,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    Duration timeout = defaultReportUploadTimeout,
  }) {
    final reference = reportReference(userId: userId, fileName: fileName);
    final uploadTask = reference.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final subscription = uploadTask.snapshotEvents.listen((snapshot) {
      final totalBytes = snapshot.totalBytes;
      if (totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / totalBytes);
      }
    }, onError: (_) {});

    return _FirebaseReportUpload(
      reference: reference,
      uploadTask: uploadTask,
      progressSubscription: subscription,
      timeout: timeout,
    );
  }
}

class _FirebaseReportUpload implements ReportUpload {
  _FirebaseReportUpload({
    required Reference reference,
    required UploadTask uploadTask,
    required StreamSubscription<TaskSnapshot> progressSubscription,
    required Duration timeout,
  }) : _reference = reference,
       _uploadTask = uploadTask,
       _progressSubscription = progressSubscription,
       _timeout = timeout {
    _result = _complete();
  }

  final Reference _reference;
  final UploadTask _uploadTask;
  final StreamSubscription<TaskSnapshot> _progressSubscription;
  final Duration _timeout;
  late final Future<String> _result;

  @override
  Future<String> get result => _result;

  Future<String> _complete() async {
    try {
      await _uploadTask.timeout(_timeout);
    } on TimeoutException {
      try {
        await _uploadTask.cancel();
      } catch (_) {
        // Preserve the timeout as the actionable failure for the caller.
      }
      throw ReportUploadTimeoutException(_timeout);
    } finally {
      await _progressSubscription.cancel();
    }
    return _reference.getDownloadURL();
  }

  @override
  Future<bool> cancel() => _uploadTask.cancel();
}
