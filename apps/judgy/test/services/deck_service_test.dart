import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:judgy/services/preferences_service.dart';
import 'package:judgy/models/game_models.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeckService', () {
    late MockPreferencesService mockPrefs;
    late DeckService deckService;

    const mockAdjectivesCsv = '''
Category,Adjective,Optional
Cool,Awesome
Cool,Rad
Bad,Terrible
''';

    const mockNounsCsv = '''
Category,Noun,Text
Animals,Dog,A good boy
Animals,Cat,A good girl
Things,Rock,A solid object
''';

    setUp(() {
      mockPrefs = MockPreferencesService();
      when(() => mockPrefs.getStringList(any())).thenReturn(null);
      when(
        () => mockPrefs.setStringList(any(), any()),
      ).thenAnswer((_) async => {});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
            final String key = utf8.decode(message!.buffer.asUint8List());
            if (key.contains('adjectives.csv')) {
              return ByteData.view(
                Uint8List.fromList(utf8.encode(mockAdjectivesCsv)).buffer,
              );
            } else if (key.contains('nouns.csv')) {
              return ByteData.view(
                Uint8List.fromList(utf8.encode(mockNounsCsv)).buffer,
              );
            }
            return null;
          });

      deckService = DeckService(mockPrefs);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('initializes and parses correctly', () async {
      await deckService.init();

      expect(deckService.isInitialized, isTrue);
      expect(
        deckService.availableCategories,
        containsAll(['Cool', 'Bad', 'Animals', 'Things']),
      );

      final activeAdjectives = deckService.getActiveAdjectives();
      expect(activeAdjectives.length, 3);
      expect(activeAdjectives.first.text, 'Awesome');
      expect(activeAdjectives.first.category, 'Cool');

      final activeNouns = deckService.getActiveNouns();
      expect(activeNouns.length, 3);
      expect(activeNouns.first.text, 'A good boy'); // index 2
      expect(activeNouns.first.type, CardType.noun);
    });

    test('toggling categories filters active cards', () async {
      await deckService.init();

      // Disable 'Cool'
      deckService.toggleCategory('Cool', isEnabled: false);

      expect(deckService.enabledCategories, isNot(contains('Cool')));

      final activeAdjectives = deckService.getActiveAdjectives();
      // Only 'Bad' should be left (Terrible)
      expect(activeAdjectives.length, 1);
      expect(activeAdjectives.first.text, 'Terrible');

      // Should save to preferences
      verify(
        () => mockPrefs.setStringList('enabled_categories', any()),
      ).called(1);
    });

    test('prevents disabling the last category', () async {
      await deckService.init();

      // Disable all but one
      deckService.toggleCategory('Cool', isEnabled: false);
      deckService.toggleCategory('Bad', isEnabled: false);
      deckService.toggleCategory('Things', isEnabled: false);

      // Now 'Animals' is the only one left. Try shutting it off.
      deckService.toggleCategory('Animals', isEnabled: false);

      // It should still be enabled
      expect(deckService.enabledCategories, contains('Animals'));
      expect(deckService.enabledCategories.length, 1);
    });
  });
}
