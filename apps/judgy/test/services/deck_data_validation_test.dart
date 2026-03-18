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

      // Build set of valid adjective category IDs.
      final adjectiveCategoryIds = <String>{};
      final adjectiveCategoryHeader = _headerIndex(adjectiveCategoryRows.first);
      final adjectiveCategoryIdIndex = adjectiveCategoryHeader['id'] ?? 0;

      for (final row in adjectiveCategoryRows.skip(1)) {
        final id = _cell(row, adjectiveCategoryIdIndex);
        if (id.isNotEmpty) {
          adjectiveCategoryIds.add(id);
        }
      }

      // Build set of valid noun category IDs.
      final nounCategoryIds = <String>{};
      final nounCategoryHeader = _headerIndex(nounCategoryRows.first);
      final nounCategoryIdIndex = nounCategoryHeader['id'] ?? 0;

      for (final row in nounCategoryRows.skip(1)) {
        final id = _cell(row, nounCategoryIdIndex);
        if (id.isNotEmpty) {
          nounCategoryIds.add(id);
        }
      }

      // Validate adjectives reference valid category IDs.
      final usedAdjectiveCategoryIds = <String>{};
      final adjectiveHeader = _headerIndex(adjectivesRows.first);
      final adjectiveCategoryIdColIndex = adjectiveHeader['category_id'] ?? 1;
      final adjectiveTextIndex = adjectiveHeader['adjective'] ?? 2;

      for (final row in adjectivesRows.skip(1)) {
        final categoryId = _cell(row, adjectiveCategoryIdColIndex);
        final adjective = _cell(row, adjectiveTextIndex);

        expect(
          categoryId,
          isNotEmpty,
          reason: 'Adjective row missing category_id: $row',
        );
        expect(
          adjective,
          isNotEmpty,
          reason: 'Adjective row missing adjective text: $row',
        );
        expect(
          adjectiveCategoryIds.contains(categoryId),
          isTrue,
          reason:
              'Adjective category_id "$categoryId" is not defined in adjective_categories.csv',
        );

        usedAdjectiveCategoryIds.add(categoryId);
      }

      // Validate nouns reference valid category IDs.
      final usedNounCategoryIds = <String>{};
      final nounHeader = _headerIndex(nounsRows.first);
      final nounCategoryIdColIndex = nounHeader['category_id'] ?? 1;
      final nounTextIndex = nounHeader['noun'] ?? 2;

      for (final row in nounsRows.skip(1)) {
        final categoryId = _cell(row, nounCategoryIdColIndex);
        final noun = _cell(row, nounTextIndex);

        expect(
          categoryId,
          isNotEmpty,
          reason: 'Noun row missing category_id: $row',
        );
        expect(
          noun,
          isNotEmpty,
          reason: 'Noun row missing noun text: $row',
        );
        expect(
          nounCategoryIds.contains(categoryId),
          isTrue,
          reason:
              'Noun category_id "$categoryId" is not defined in noun_categories.csv',
        );

        usedNounCategoryIds.add(categoryId);
      }

      final adjectiveCategoriesWithoutCards = adjectiveCategoryIds.difference(
        usedAdjectiveCategoryIds,
      );
      expect(
        adjectiveCategoriesWithoutCards,
        isEmpty,
        reason:
            'IDs in adjective_categories.csv missing cards: '
            '${adjectiveCategoriesWithoutCards.toList()}',
      );

      final nounCategoriesWithoutCards = nounCategoryIds.difference(
        usedNounCategoryIds,
      );
      expect(
        nounCategoriesWithoutCards,
        isEmpty,
        reason:
            'IDs in noun_categories.csv missing cards: '
            '${nounCategoriesWithoutCards.toList()}',
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
