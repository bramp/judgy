import 'package:flutter_test/flutter_test.dart';
import 'package:judgy/services/analytics_service.dart';
import 'package:judgy/services/consent_service.dart';
import 'package:mocktail/mocktail.dart';

class MockConsentService extends Mock implements ConsentService {}

void main() {
  group('AnalyticsService', () {
    late MockConsentService mockConsentService;

    setUp(() {
      mockConsentService = MockConsentService();
    });

    test('logEvent does not throw when Firebase is uninitialized', () {
      when(() => mockConsentService.analyticsAllowed).thenReturn(true);
      final service = AnalyticsService(mockConsentService);

      // Should exit early because Firebase.apps is empty in test environment,
      // preventing any crashes from uninitialized Firebase.
      expect(
        () => service.logEvent(name: 'test_event', parameters: {'score': 10}),
        returnsNormally,
      );
    });

    test('logEvent does not throw when analytics is not allowed', () {
      when(() => mockConsentService.analyticsAllowed).thenReturn(false);
      final service = AnalyticsService(mockConsentService);

      // Should exit early because analyticsAllowed is false.
      expect(
        () => service.logEvent(name: 'test_event'),
        returnsNormally,
      );
    });
  });
}
