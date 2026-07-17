import 'package:firebase_crashlytics/firebase_crashlytics.dart';

abstract class CrashlyticsGateway {
  Future<void> recordHandledDemoException();

  Future<void> triggerTestCrash();
}

class CrashlyticsService implements CrashlyticsGateway {
  CrashlyticsService._();

  static final CrashlyticsService instance = CrashlyticsService._();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> recordHandledException(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  @override
  Future<void> recordHandledDemoException() async {
    try {
      await _crashlytics.log('Phase 7 handled exception demo requested');
      await _crashlytics.setCustomKey(
        'firebase_demo_type',
        'handled_exception',
      );
    } catch (_) {
      // Metadata is helpful for evidence but must not block the report itself.
    }
    await recordHandledException(
      StateError('Phase 7 handled exception demo'),
      StackTrace.current,
      reason: 'User triggered the handled exception demo from Profile',
    );
  }

  @override
  Future<void> triggerTestCrash() async {
    try {
      await _crashlytics.log('Phase 7 fatal crash demo confirmed');
      await _crashlytics.setCustomKey('firebase_demo_type', 'fatal_test_crash');
    } catch (_) {
      // A metadata failure must not make the explicitly confirmed test a no-op.
    }
    _crashlytics.crash();
  }
}
