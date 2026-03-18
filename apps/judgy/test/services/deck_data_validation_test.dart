import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Deck CSV validation', () {
    test('adjectives and nouns align with category definition files', () {
      final adjectivesRows = _readCsvRows('assets/data/adjectives.csv');
      final nounsRows = _readCsvRows('assets/data/nouns.csv');
      final adjectiveCategoryRows = _readCsvRows(
        'assets/data/adjective_categories.csv',
      );
      final nounCategoryRows = _readCsvRows('assets/data/noun_categories.csv');

      expect(adjectivesRows, isNotEmpty);
      expect(nounsRows, isNotEmpty);
      expect(adjectiveCategoryRows, isNotEmpty);
      expect(nounCategoryRows, isNotEmpty);

      final adjectiveCategories = <String>{};
      final adjectiveCategoryHeader = _headerIndex(adjectiveCategoryRows.first);
      final adjectiveCategoryIndex = adjectiveCategoryHeader['category'] ?? 1;

      for (final row in adjectiveCategoryRows.skip(1)) {
        final category = _cell(row, adjectiveCategoryIndex);
        if (category.isNotEmpty) {
          adjectiveCategories.add(category);
        }
      }

      final nounCategoryPaths = <String>{};
      final nounCategoryHeader = _headerIndex(nounCategoryRows.first);
      final nounCategoryIndex = nounCategoryHeader['category'] ?? 1;
      final nounSubcategoryIndex = nounCategoryHeader['subcategory'] ?? 2;

      for (final row in nounCategoryRows.skip(1)) {
        final category = _cell(row, nounCategoryIndex);
        final subcategory = _cell(row, nounSubcategoryIndex);
        if (category.isNotEmpty && subcategory.isNotEmpty) {
          nounCategoryPaths.add('$category|$subcategory');
        }
      }

      final adjectiveCardCategories = <String>{};
      final adjectiveHeader = _headerIndex(adjectivesRows.first);
      final adjectiveCardCategoryIndex = adjectiveHeader['category'] ?? 0;
      final adjectiveTextIndex = adjectiveHeader['adjective'] ?? 1;

      for (final row in adjectivesRows.skip(1)) {
        final category = _cell(row, adjectiveCardCategoryIndex);
        final adjective = _cell(row, adjectiveTextIndex);

        expect(
          category,
          isNotEmpty,
          reason: 'Adjective row missing category: $row',
        );
        expect(
          adjective,
          isNotEmpty,
          reason: 'Adjective row missing adjective text: $row',
        );
        expect(
          adjectiveCategories.contains(category),
          isTrue,
          reason:
              'Adjective category "$category" is not defined in adjective_categories.csv',
        );

        adjectiveCardCategories.add(category);
      }

      final nounCardPaths = <String>{};
      final nounHeader = _headerIndex(nounsRows.first);
      final nounCardCategoryIndex = nounHeader['category'] ?? 0;
      final nounCardSubcategoryIndex = nounHeader['subcategory'] ?? 1;
      final nounTextIndex = nounHeader['noun'] ?? 2;

      for (final row in nounsRows.skip(1)) {
        final category = _cell(row, nounCardCategoryIndex);
        final subcategory = _cell(row, nounCardSubcategoryIndex);
        final noun = _cell(row, nounTextIndex);

        expect(category, isNotEmpty, reason: 'Noun row missing category: $row');
        expect(
          subcategory,
          isNotEmpty,
          reason: 'Noun row missing subcategory: $row',
        );
        expect(noun, isNotEmpty, reason: 'Noun row missing noun text: $row');

        final path = '$category|$subcategory';
        expect(
          nounCategoryPaths.contains(path),
          isTrue,
          reason: 'Noun path "$path" is not defined in noun_categories.csv',
        );

        nounCardPaths.add(path);
      }

      final adjectiveCategoriesWithoutCards = adjectiveCategories.difference(
        adjectiveCardCategories,
      );
      expect(
        adjectiveCategoriesWithoutCards,
        isEmpty,
        reason:
            'Categories in adjective_categories.csv missing cards: '
            '${adjectiveCategoriesWithoutCards.toList()}',
      );

      final nounPathsWithoutCards = nounCategoryPaths.difference(nounCardPaths);
      expect(
        nounPathsWithoutCards,
        isEmpty,
        reason:
            'Paths in noun_categories.csv missing cards: '
            '${nounPathsWithoutCards.toList()}',
      );
    });
  });
}

List<List<dynamic>> _readCsvRows(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'Missing CSV file: $path');

  final content = file.readAsStringSync();
  final rows = const CsvDecoder().convert(content);
  expect(rows, isNotEmpty, reason: 'CSV has no rows: $path');

  return rows;
}

Map<String, int> _headerIndex(List<dynamic> headerRow) {
  final index = <String, int>{};
  for (var i = 0; i < headerRow.length; i++) {
    final key = headerRow[i].toString().trim().toLowerCase();
    if (key.isNotEmpty) {
      index[key] = i;
    }
  }
  return index;
}

String _cell(List<dynamic> row, int index) {
  if (index < 0 || index >= row.length) return '';
  return row[index].toString().trim();
}
