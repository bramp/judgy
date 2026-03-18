import 'package:flutter_test/flutter_test.dart';
import 'package:judgy/services/consent_service.dart';
import 'package:judgy/services/preferences_service.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  group('ConsentService', () {
    late MockPreferencesService mockPrefs;

    setUp(() {
      mockPrefs = MockPreferencesService();
    });

    test('needsConsent is false in debug override', () {
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      final service = ConsentService(mockPrefs, debugOverride: true);

      expect(service.needsConsent, isFalse);
      expect(service.analyticsAllowed, isTrue);
    });

    test('needsConsent is true if not set and no debug override', () {
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      final service = ConsentService(mockPrefs, debugOverride: false);

      expect(service.needsConsent, isTrue);
      expect(service.analyticsAllowed, isFalse);
    });

    test('analyticsAllowed is true if previously accepted', () {
      when(() => mockPrefs.getBool('analytics_consent')).thenReturn(true);
      final service = ConsentService(mockPrefs, debugOverride: false);

      expect(service.needsConsent, isFalse);
      expect(service.analyticsAllowed, isTrue);
    });

    test('analyticsAllowed is false if previously declined', () {
      when(() => mockPrefs.getBool('analytics_consent')).thenReturn(false);
      final service = ConsentService(mockPrefs, debugOverride: false);

      expect(service.needsConsent, isFalse);
      expect(service.analyticsAllowed, isFalse);
    });

    test(
      'setAnalyticsConsent saves preference and notifies listeners',
      () async {
        when(() => mockPrefs.getBool('analytics_consent')).thenReturn(null);
        when(
          () => mockPrefs.setBool(any(), value: any(named: 'value')),
        ).thenAnswer((_) async => {});

        final service = ConsentService(mockPrefs, debugOverride: false);
        var notified = false;
        service.addListener(() => notified = true);

        await service.setAnalyticsConsent(allowed: true);

        verify(
          () => mockPrefs.setBool('analytics_consent', value: true),
        ).called(1);
        expect(service.analyticsAllowed, isTrue);
        expect(notified, isTrue);
      },
    );
  });
}
