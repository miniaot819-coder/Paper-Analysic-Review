import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/firebase/analytics_tracking_service.dart';

void main() {
  test('catalog contains exactly the seven required Lab 03 events', () {
    expect(AnalyticsTrackingService.requiredEventNames, {
      'login',
      'search_topic',
      'view_publication',
      'view_journal',
      'view_keyword',
      'export_pdf',
      'logout',
    });
  });

  test('normalizes and safely truncates Analytics string parameters', () {
    final value = '  ${List.filled(101, '📚').join()}  ';

    final normalized = AnalyticsTrackingService.normalizeStringParameter(value);

    expect(normalized.runes.length, 100);
    expect(normalized, isNot(contains(' ')));
    expect(normalized.endsWith('📚'), isTrue);
  });

  test('keeps short Analytics string parameters after trimming', () {
    expect(
      AnalyticsTrackingService.normalizeStringParameter('  OpenAlex  '),
      'OpenAlex',
    );
  });
}
