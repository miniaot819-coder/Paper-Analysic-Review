import 'package:firebase_remote_config/firebase_remote_config.dart';

abstract class RemoteConfigGateway {
  int get maxJournals;
  int get maxKeywords;

  Future<bool> refreshForDemo();
}

class RemoteConfigService implements RemoteConfigGateway {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  static const String maxJournalsKey = 'max_journals_displayed';
  static const String maxKeywordsKey = 'max_keywords_displayed';

  FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    try {
      await _configure(minimumFetchInterval: const Duration(hours: 1));
      _initialized = true;
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Remote Config must not disable Authentication or Analytics when the
      // device is offline or the Console setup is not ready yet.
    }
  }

  @override
  int get maxJournals => _positiveValue(maxJournalsKey, fallback: 10);
  @override
  int get maxKeywords => _positiveValue(maxKeywordsKey, fallback: 10);

  @override
  Future<bool> refreshForDemo() async {
    await _configure(minimumFetchInterval: Duration.zero);
    _initialized = true;
    try {
      return await _remoteConfig.fetchAndActivate();
    } finally {
      try {
        await _configure(minimumFetchInterval: const Duration(hours: 1));
      } catch (_) {
        // A successful fetch should remain usable even if restoring the
        // production-friendly interval fails temporarily.
      }
    }
  }

  Future<void> _configure({required Duration minimumFetchInterval}) async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: minimumFetchInterval,
      ),
    );
    await _remoteConfig.setDefaults(const {
      maxJournalsKey: 10,
      maxKeywordsKey: 10,
    });
  }

  int _positiveValue(String key, {required int fallback}) {
    try {
      final value = _remoteConfig.getInt(key);
      return value > 0 ? value : fallback;
    } catch (_) {
      return fallback;
    }
  }
}
