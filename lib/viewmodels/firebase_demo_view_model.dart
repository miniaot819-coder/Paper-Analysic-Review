import 'package:flutter/foundation.dart';

import '../firebase/crashlytics_service.dart';
import '../firebase/remote_config_service.dart';

class FirebaseDemoViewModel extends ChangeNotifier {
  FirebaseDemoViewModel({
    RemoteConfigGateway? remoteConfig,
    CrashlyticsGateway? crashlytics,
  }) : _remoteConfig = remoteConfig ?? RemoteConfigService.instance,
       _crashlytics = crashlytics ?? CrashlyticsService.instance {
    _readConfigValues();
  }

  final RemoteConfigGateway _remoteConfig;
  final CrashlyticsGateway _crashlytics;

  int _maxJournals = 10;
  int _maxKeywords = 10;
  bool _isRefreshingConfig = false;
  bool _isRecordingHandledException = false;
  String? _remoteConfigMessage;
  String? _remoteConfigError;
  String? _crashlyticsMessage;
  String? _crashlyticsError;
  bool _isDisposed = false;

  int get maxJournals => _maxJournals;
  int get maxKeywords => _maxKeywords;
  bool get isRefreshingConfig => _isRefreshingConfig;
  bool get isRecordingHandledException => _isRecordingHandledException;
  String? get remoteConfigMessage => _remoteConfigMessage;
  String? get remoteConfigError => _remoteConfigError;
  String? get crashlyticsMessage => _crashlyticsMessage;
  String? get crashlyticsError => _crashlyticsError;

  Future<void> refreshRemoteConfig() async {
    if (_isRefreshingConfig) return;
    _isRefreshingConfig = true;
    _remoteConfigMessage = null;
    _remoteConfigError = null;
    _notifyListeners();

    try {
      final activated = await _remoteConfig.refreshForDemo();
      if (_isDisposed) return;
      _readConfigValues();
      _remoteConfigMessage = activated
          ? 'New values were fetched and activated from Firebase.'
          : 'Fetch completed successfully; the current values are unchanged.';
    } catch (_) {
      if (_isDisposed) return;
      _remoteConfigError =
          'Unable to refresh Remote Config. Check your network and Firebase Console.';
    } finally {
      _isRefreshingConfig = false;
      _notifyListeners();
    }
  }

  Future<void> recordHandledException() async {
    if (_isRecordingHandledException) return;
    _isRecordingHandledException = true;
    _crashlyticsMessage = null;
    _crashlyticsError = null;
    _notifyListeners();

    try {
      await _crashlytics.recordHandledDemoException();
      if (_isDisposed) return;
      _crashlyticsMessage =
          'Handled exception sent. Check the Crashlytics Console.';
    } catch (_) {
      if (_isDisposed) return;
      _crashlyticsError =
          'Unable to send the handled exception. Please try again.';
    } finally {
      _isRecordingHandledException = false;
      _notifyListeners();
    }
  }

  Future<void> triggerTestCrash() {
    return _crashlytics.triggerTestCrash();
  }

  void _readConfigValues() {
    _maxJournals = _remoteConfig.maxJournals;
    _maxKeywords = _remoteConfig.maxKeywords;
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
