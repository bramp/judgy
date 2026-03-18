import 'package:csv/csv.dart';
import 'package:judgy/models/game_models.dart';

/// Utility class to parse CSV files into deck models.
class DeckParser {
  static const _decoder = CsvDecoder(parseHeaders: true);

  static List<CsvRow> _decode(String csvString) {
    if (csvString.trim().isEmpty) return [];
    return _decoder.convert(csvString).cast<CsvRow>();
  }

  /// Parses adjectives.csv. Requires [categoryMap] (id→category name) from
  /// [parseAdjectiveCategoriesCsv] to resolve `category_id` foreign keys.
  static List<CardModel> parseAdjectivesCsv(
    String csvString,
    Map<String, String> categoryMap,
  ) {
    final rows = _decode(csvString);
    final cards = <CardModel>[];

    for (final row in rows) {
      final id = row['id']?.toString().trim();
      final categoryId = row['category_id']?.toString().trim();
      final adjective = row['adjective']?.toString().trim();

      if (id == null ||
          id.isEmpty ||
          categoryId == null ||
          categoryId.isEmpty ||
          adjective == null ||
          adjective.isEmpty) {
        assert(false, 'Adjective row missing required fields: $row');
        continue;
      }

      final category = categoryMap[categoryId];
      if (category == null) {
        assert(
          false,
          'Adjective "$id" references unknown category_id "$categoryId".',
        );
        continue;
      }

      cards.add(
        CardModel(
          id: id,
          text: adjective,
          type: CardType.adjective,
          category: category,
        ),
      );
    }
    return cards;
  }

  /// Parses nouns.csv. Requires [categoryMap] (id→(category, subcategory))
  /// from [parseNounCategoriesCsv] to resolve `category_id` foreign keys.
  static List<CardModel> parseNounsCsv(
    String csvString,
    Map<String, (String, String)> categoryMap,
  ) {
    final rows = _decode(csvString);
    final cards = <CardModel>[];

    for (final row in rows) {
      final id = row['id']?.toString().trim();
      final categoryId = row['category_id']?.toString().trim();
      final noun = row['noun']?.toString().trim();

      if (id == null ||
          id.isEmpty ||
          categoryId == null ||
          categoryId.isEmpty ||
          noun == null ||
          noun.isEmpty) {
        assert(false, 'Noun row missing required fields: $row');
        continue;
      }

      final entry = categoryMap[categoryId];
      if (entry == null) {
        assert(
          false,
          'Noun "$id" references unknown category_id "$categoryId".',
        );
        continue;
      }
      final (category, subcategory) = entry;

      cards.add(
        CardModel(
          id: id,
          text: noun,
          type: CardType.noun,
          category: category,
          subcategory: subcategory,
        ),
      );
    }
    return cards;
  }

  /// Parses adjective_categories.csv into a map of id→category name.
  static Map<String, String> parseAdjectiveCategoriesCsv(String csvString) {
    final rows = _decode(csvString);
    final map = <String, String>{};

    for (final row in rows) {
      final id = row['id']?.toString().trim();
      final category = row['category']?.toString().trim();
      if (id != null &&
          id.isNotEmpty &&
          category != null &&
          category.isNotEmpty) {
        map[id] = category;
      }
    }
    return map;
  }

  /// Parses noun_categories.csv into a map of id→(category, subcategory).
  static Map<String, (String, String)> parseNounCategoriesCsv(
    String csvString,
  ) {
    final rows = _decode(csvString);
    final map = <String, (String, String)>{};

    for (final row in rows) {
      final id = row['id']?.toString().trim();
      final category = row['category']?.toString().trim();
      final subcategory = row['subcategory']?.toString().trim();

      if (id != null &&
          id.isNotEmpty &&
          category != null &&
          category.isNotEmpty &&
          subcategory != null &&
          subcategory.isNotEmpty) {
        map[id] = (category, subcategory);
      }
    }
    return map;
  }
}
