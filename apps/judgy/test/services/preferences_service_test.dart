import 'package:flutter_test/flutter_test.dart';
import 'package:judgy/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PreferencesService', () {
    late PreferencesService preferencesService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'testString': 'hello',
        'testBool': true,
        'testStringList': ['a', 'b', 'c'],
      });
      preferencesService = await PreferencesService.init();
    });

    test('reads existing string values correctly', () {
      expect(preferencesService.getString('testString'), 'hello');
      expect(preferencesService.getString('missingString'), isNull);
    });

    test('reads existing bool values correctly', () {
      expect(preferencesService.getBool('testBool'), isTrue);
      expect(preferencesService.getBool('missingBool'), isNull);
    });

    test('reads existing string list values correctly', () {
      expect(preferencesService.getStringList('testStringList'), [
        'a',
        'b',
        'c',
      ]);
      expect(preferencesService.getStringList('missingList'), isNull);
    });

    test('writes string values correctly', () async {
      await preferencesService.setString('newString', 'world');
      expect(preferencesService.getString('newString'), 'world');
    });

    test('writes bool values correctly', () async {
      await preferencesService.setBool('newBool', value: false);
      expect(preferencesService.getBool('newBool'), isFalse);
    });

    test('writes string list values correctly', () async {
      await preferencesService.setStringList('newList', ['x', 'y']);
      expect(preferencesService.getStringList('newList'), ['x', 'y']);
    });

    test('removes values correctly', () async {
      await preferencesService.remove('testString');
      expect(preferencesService.getString('testString'), isNull);
    });
  });
}
