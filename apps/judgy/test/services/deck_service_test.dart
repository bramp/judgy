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
Category,Adjective,Description
Cool,Awesome,Something awesome
Cool,Rad,Something rad
Bad,Terrible,Something terrible
''';

    const mockNounsCsv = '''
Category,SubCategory,Noun,Description
Animals,Mammals,Dog,A good boy
Animals,Mammals,Cat,A good girl
Things,Objects,Rock,A solid object
Things,Objects,Tree,A living thing
''';

    const mockAdjectiveCategoriesCsv = '''
  id,category
  ac-cool,Cool
  ac-bad,Bad
  ''';

    const mockNounCategoriesCsv = '''
  id,category,subcategory
  nc-animals_mammals,Animals,Mammals
  nc-things_objects,Things,Objects
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
            } else if (key.contains('adjective_categories.csv')) {
              return ByteData.view(
                Uint8List.fromList(
                  utf8.encode(mockAdjectiveCategoriesCsv),
                ).buffer,
              );
            } else if (key.contains('noun_categories.csv')) {
              return ByteData.view(
                Uint8List.fromList(utf8.encode(mockNounCategoriesCsv)).buffer,
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
        deckService.adjectiveCategories,
        containsAll(['Cool', 'Bad']),
      );
      expect(
        deckService.nounCategoryMap.keys,
        containsAll(['Animals', 'Things']),
      );

      final activeAdjectives = deckService.getActiveAdjectives();
      expect(activeAdjectives.length, 3);
      expect(activeAdjectives.first.text, 'Awesome');
      expect(activeAdjectives.first.category, 'Cool');

      final activeNouns = deckService.getActiveNouns();
      expect(activeNouns.length, 4);
      expect(activeNouns[0].text, 'Dog');
      expect(activeNouns[0].category, 'Animals');
      expect(activeNouns[0].subcategory, 'Mammals');
      expect(activeNouns[0].type, CardType.noun);
    });

    test('toggling adjective categories filters active cards', () async {
      await deckService.init();

      // Disable 'Cool'
      deckService.toggleAdjectiveCategory('Cool', isEnabled: false);

      expect(deckService.isAdjectiveCategoryEnabled('Cool'), isFalse);

      final activeAdjectives = deckService.getActiveAdjectives();
      // Only 'Bad' should be left (Terrible)
      expect(activeAdjectives.length, 1);
      expect(activeAdjectives.first.text, 'Terrible');

      // Should save to preferences
      verify(
        () => mockPrefs.setStringList('enabled_categories', any()),
      ).called(1);
    });

    test('toggling noun subcategories filters active cards', () async {
      await deckService.init();

      // Disable 'Mammals' in 'Animals'
      deckService.toggleNounSubcategory(
        'Animals',
        'Mammals',
        isEnabled: false,
      );

      expect(
        deckService.isNounSubcategoryEnabled('Animals', 'Mammals'),
        isFalse,
      );

      final activeNouns = deckService.getActiveNouns();
      // Only 'Things' subcategories should remain
      expect(activeNouns.length, 2);
      expect(activeNouns.every((c) => c.category == 'Things'), isTrue);
    });

    test('prevents disabling the last category/subcategory', () async {
      await deckService.init();

      // Disable all adjectives except 'Bad'
      deckService.toggleAdjectiveCategory('Cool', isEnabled: false);

      // Disable all noun subcategories except 'Things|Objects'
      deckService.toggleNounSubcategory('Animals', 'Mammals', isEnabled: false);
      deckService.toggleNounSubcategory('Things', 'Objects', isEnabled: false);

      // Now try to disable 'Bad' - should not work
      deckService.toggleAdjectiveCategory('Bad', isEnabled: false);

      // It should still be enabled
      expect(deckService.isAdjectiveCategoryEnabled('Bad'), isTrue);
    });

    test('gets correct category status maps', () async {
      await deckService.init();

      final adjStatus = deckService.getAdjectiveStatus();
      expect(adjStatus['Cool'], isTrue);
      expect(adjStatus['Bad'], isTrue);

      final nounStatus = deckService.getNounStatus();
      expect(nounStatus['Animals']?['Mammals'], isTrue);
      expect(nounStatus['Things']?['Objects'], isTrue);

      // Toggle and check
      deckService.toggleNounSubcategory('Animals', 'Mammals', isEnabled: false);
      final updatedNounStatus = deckService.getNounStatus();
      expect(updatedNounStatus['Animals']?['Mammals'], isFalse);
    });
  });
}
