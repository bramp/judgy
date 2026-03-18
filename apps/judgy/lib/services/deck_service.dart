import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:judgy/models/game_models.dart';
import 'package:judgy/services/preferences_service.dart';

class DeckService extends ChangeNotifier {
  DeckService(this._preferencesService);

  final PreferencesService _preferencesService;

  static const String _categoriesKey = 'enabled_categories';
  static const String _pathSeparator = '|';

  List<CardModel> _allAdjectives = [];
  List<CardModel> _allNouns = [];

  // Maps: category -> list of subcategories (for nouns)
  final Map<String, Set<String>> _nounCategoryMap = {};
  // All top-level categories (adjectives)
  final Set<String> _adjectiveCategories = {};

  // Enabled paths: either "Category" or "Category|SubCategory"
  Set<String> _enabledPaths = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Map<String, Set<String>> get nounCategoryMap => _nounCategoryMap;
  Set<String> get adjectiveCategories => _adjectiveCategories;

  /// Returns a map of category -> enabled status for adjectives
  Map<String, bool> getAdjectiveStatus() {
    final status = <String, bool>{};
    for (final category in _adjectiveCategories) {
      status[category] = _enabledPaths.contains(category);
    }
    return status;
  }

  /// Returns a map of category -> (subcategory -> enabled status) for nouns
  Map<String, Map<String, bool>> getNounStatus() {
    final status = <String, Map<String, bool>>{};
    for (final entry in _nounCategoryMap.entries) {
      final category = entry.key;
      final subcategories = entry.value;
      status[category] = {};
      for (final subcategory in subcategories) {
        final path = '$category$_pathSeparator$subcategory';
        status[category]![subcategory] = _enabledPaths.contains(path);
      }
    }
    return status;
  }

  bool isAdjectiveCategoryEnabled(String category) {
    return _enabledPaths.contains(category);
  }

  bool isNounSubcategoryEnabled(String category, String subcategory) {
    final path = '$category$_pathSeparator$subcategory';
    return _enabledPaths.contains(path);
  }

  Future<void> init() async {
    if (_isInitialized) return;

    final adjCsv = await rootBundle.loadString('assets/data/adjectives.csv');
    final nounCsv = await rootBundle.loadString('assets/data/nouns.csv');
    final adjCategoryCsv = await rootBundle.loadString(
      'assets/data/adjective_categories.csv',
    );
    final nounCategoryCsv = await rootBundle.loadString(
      'assets/data/noun_categories.csv',
    );

    _allAdjectives = _parseAdjectivesCsv(adjCsv);
    _allNouns = _parseNounsCsv(nounCsv);
    final adjectiveCategoryDefs = _parseAdjectiveCategoriesCsv(adjCategoryCsv);
    final nounCategoryDefs = _parseNounCategoriesCsv(nounCategoryCsv);

    _adjectiveCategories
      ..clear()
      ..addAll(adjectiveCategoryDefs);

    _nounCategoryMap
      ..clear()
      ..addAll(nounCategoryDefs);

    _validateDeckData();

    // Load saved enabled paths
    final saved = _preferencesService.getStringList(_categoriesKey);
    if (saved != null && saved.isNotEmpty) {
      _enabledPaths = saved.toSet();
      // Validate against current structure
      _validateEnabledPaths();
      if (_enabledPaths.isEmpty) {
        _enableAllPaths();
      }
    } else {
      _enableAllPaths();
    }

    _isInitialized = true;
    notifyListeners();
  }

  void _validateEnabledPaths() {
    final validPaths = <String>{};
    for (final path in _enabledPaths) {
      if (path.contains(_pathSeparator)) {
        // It's a noun category/subcategory path
        final parts = path.split(_pathSeparator);
        if (parts.length == 2) {
          final category = parts[0];
          final subcategory = parts[1];
          if (_nounCategoryMap[category]?.contains(subcategory) ?? false) {
            validPaths.add(path);
          }
        }
      } else {
        // It's an adjective category
        if (_adjectiveCategories.contains(path)) {
          validPaths.add(path);
        }
      }
    }
    _enabledPaths = validPaths;
  }

  void _enableAllPaths() {
    _enabledPaths
      ..clear()
      ..addAll(_adjectiveCategories);
    for (final entry in _nounCategoryMap.entries) {
      for (final subcategory in entry.value) {
        _enabledPaths.add('${entry.key}$_pathSeparator$subcategory');
      }
    }
  }

  void toggleAdjectiveCategory(String category, {required bool isEnabled}) {
    if (isEnabled) {
      _enabledPaths.add(category);
    } else {
      // Prevent disabling the last category/subcategory combination
      if (_canDisable()) {
        _enabledPaths.remove(category);
      }
    }
    _savePaths();
    notifyListeners();
  }

  void toggleNounSubcategory(
    String category,
    String subcategory, {
    required bool isEnabled,
  }) {
    final path = '$category$_pathSeparator$subcategory';
    if (isEnabled) {
      _enabledPaths.add(path);
    } else {
      // Prevent disabling the last category/subcategory combination
      if (_canDisable()) {
        _enabledPaths.remove(path);
      }
    }
    _savePaths();
    notifyListeners();
  }

  bool _canDisable() {
    // Keep at least one path enabled
    return _enabledPaths.length > 1;
  }

  void _savePaths() {
    // ignore: discarded_futures, Preferences are set optimistically
    _preferencesService.setStringList(
      _categoriesKey,
      _enabledPaths.toList(),
    );
  }

  List<CardModel> getActiveAdjectives() {
    final list = _allAdjectives
        .where((c) => _enabledPaths.contains(c.category))
        .toList();
    return list.isNotEmpty ? list : _allAdjectives.toList();
  }

  List<CardModel> getActiveNouns() {
    final list = _allNouns.where((c) {
      if (c.category == null) return false;
      final path = '${c.category}$_pathSeparator${c.subcategory}';
      return _enabledPaths.contains(path);
    }).toList();
    return list.isNotEmpty ? list : _allNouns.toList();
  }

  List<CardModel> _parseAdjectivesCsv(String csvString) {
    final rows = const CsvDecoder().convert(csvString);
    if (rows.length < 2) return <CardModel>[];

    final headerIndex = _buildHeaderIndex(rows.first);
    final categoryIndex = _indexFor(headerIndex, 'category', fallback: 0);
    final adjectiveIndex = _indexFor(headerIndex, 'adjective', fallback: 1);

    final cards = <CardModel>[];
    var idCounter = 1;
    for (final row in rows.skip(1)) {
      if (row.isEmpty) continue;

      final category = _csvCell(row, categoryIndex);
      final text = _csvCell(row, adjectiveIndex);

      if (text.isNotEmpty && category.isNotEmpty) {
        cards.add(
          CardModel(
            id: 'adjective_${category.hashCode}_${idCounter++}',
            text: text,
            type: CardType.adjective,
            category: category,
          ),
        );
      }
    }
    return cards;
  }

  List<CardModel> _parseNounsCsv(String csvString) {
    final rows = const CsvDecoder().convert(csvString);
    if (rows.length < 2) return <CardModel>[];

    final headerIndex = _buildHeaderIndex(rows.first);
    final categoryIndex = _indexFor(headerIndex, 'category', fallback: 0);
    final subcategoryIndex = _indexFor(headerIndex, 'subcategory', fallback: 1);
    final nounIndex = _indexFor(headerIndex, 'noun', fallback: 2);

    final cards = <CardModel>[];
    var idCounter = 1;
    for (final row in rows.skip(1)) {
      if (row.isEmpty) continue;

      final category = _csvCell(row, categoryIndex);
      final subcategory = _csvCell(row, subcategoryIndex);
      final text = _csvCell(row, nounIndex);

      if (text.isNotEmpty && category.isNotEmpty && subcategory.isNotEmpty) {
        cards.add(
          CardModel(
            id: 'noun_${category.hashCode}_${subcategory.hashCode}_${idCounter++}',
            text: text,
            type: CardType.noun,
            category: category,
            subcategory: subcategory,
          ),
        );
      }
    }
    return cards;
  }

  Set<String> _parseAdjectiveCategoriesCsv(String csvString) {
    final rows = const CsvDecoder().convert(csvString);
    if (rows.length < 2) {
      throw const FormatException(
        'No adjective categories found in adjective_categories.csv.',
      );
    }

    final headerIndex = _buildHeaderIndex(rows.first);
    final categoryIndex = _indexFor(headerIndex, 'category', fallback: 1);

    final categories = <String>{};

    for (final row in rows.skip(1)) {
      if (row.isEmpty) continue;

      final category = _csvCell(row, categoryIndex);
      if (category.isEmpty) continue;

      if (!categories.add(category)) {
        throw FormatException(
          'Duplicate adjective category found in adjective_categories.csv: '
          '$category',
        );
      }
    }

    if (categories.isEmpty) {
      throw const FormatException(
        'No adjective categories found in adjective_categories.csv.',
      );
    }

    return categories;
  }

  Map<String, Set<String>> _parseNounCategoriesCsv(String csvString) {
    final rows = const CsvDecoder().convert(csvString);
    if (rows.length < 2) {
      throw const FormatException(
        'No noun categories found in noun_categories.csv.',
      );
    }

    final headerIndex = _buildHeaderIndex(rows.first);
    final categoryIndex = _indexFor(headerIndex, 'category', fallback: 1);
    final subcategoryIndex = _indexFor(headerIndex, 'subcategory', fallback: 2);

    final categoryMap = <String, Set<String>>{};

    for (final row in rows.skip(1)) {
      if (row.isEmpty) continue;

      final category = _csvCell(row, categoryIndex);
      final subcategory = _csvCell(row, subcategoryIndex);

      if (category.isEmpty || subcategory.isEmpty) {
        continue;
      }

      final subcategories = categoryMap.putIfAbsent(category, () => <String>{});
      if (!subcategories.add(subcategory)) {
        throw FormatException(
          'Duplicate noun category path found in noun_categories.csv: '
          '$category$_pathSeparator$subcategory',
        );
      }
    }

    if (categoryMap.isEmpty) {
      throw const FormatException(
        'No noun categories found in noun_categories.csv.',
      );
    }

    return categoryMap;
  }

  Map<String, int> _buildHeaderIndex(List<dynamic> headerRow) {
    final index = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final key = headerRow[i].toString().trim().toLowerCase();
      if (key.isNotEmpty) {
        index[key] = i;
      }
    }
    return index;
  }

  int _indexFor(
    Map<String, int> headerIndex,
    String name, {
    required int fallback,
  }) {
    return headerIndex[name] ?? fallback;
  }

  String _csvCell(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index].toString().trim();
  }

  void _validateDeckData() {
    final errors = <String>[];

    if (_allAdjectives.isEmpty) {
      errors.add('No adjective cards loaded from adjectives.csv.');
    }
    if (_allNouns.isEmpty) {
      errors.add('No noun cards loaded from nouns.csv.');
    }

    final adjectiveCardCategories = <String>{};
    for (final card in _allAdjectives) {
      final category = card.category;
      if (category == null || category.isEmpty) {
        errors.add('Adjective card "${card.text}" is missing a category.');
        continue;
      }
      adjectiveCardCategories.add(category);
      if (!_adjectiveCategories.contains(category)) {
        errors.add(
          'Adjective card "${card.text}" uses unknown category "$category".',
        );
      }
    }

    final nounCategoryPaths = <String>{};
    for (final entry in _nounCategoryMap.entries) {
      for (final subcategory in entry.value) {
        nounCategoryPaths.add('${entry.key}$_pathSeparator$subcategory');
      }
    }

    final nounCardPaths = <String>{};
    for (final card in _allNouns) {
      final category = card.category;
      final subcategory = card.subcategory;
      if (category == null || category.isEmpty) {
        errors.add('Noun card "${card.text}" is missing a category.');
        continue;
      }
      if (subcategory == null || subcategory.isEmpty) {
        errors.add('Noun card "${card.text}" is missing a subcategory.');
        continue;
      }

      final path = '$category$_pathSeparator$subcategory';
      nounCardPaths.add(path);
      if (!nounCategoryPaths.contains(path)) {
        errors.add('Noun card "${card.text}" uses unknown path "$path".');
      }
    }

    final missingAdjectiveCategories = _adjectiveCategories.difference(
      adjectiveCardCategories,
    );
    for (final category in missingAdjectiveCategories) {
      errors.add(
        'Adjective category "$category" has no cards in adjectives.csv.',
      );
    }

    final missingNounPaths = nounCategoryPaths.difference(nounCardPaths);
    for (final path in missingNounPaths) {
      errors.add('Noun category path "$path" has no cards in nouns.csv.');
    }

    if (errors.isNotEmpty) {
      throw FormatException(
        'Deck data validation failed:\n - ${errors.join('\n - ')}',
      );
    }
  }
}
