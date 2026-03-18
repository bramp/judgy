import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:judgy/models/game_models.dart';
import 'package:judgy/services/preferences_service.dart';
import 'package:judgy/utils/deck_parser.dart';

/// Service for deck operations.
class DeckService extends ChangeNotifier {
  /// Documents this public API member.
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

  /// Documents this public API member.
  bool get isInitialized => _isInitialized;

  /// Documents this public API member.
  Map<String, Set<String>> get nounCategoryMap => _nounCategoryMap;

  /// Documents this public API member.
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

  /// Documents this public API member.
  bool isAdjectiveCategoryEnabled(String category) {
    return _enabledPaths.contains(category);
  }

  /// Documents this public API member.
  bool isNounSubcategoryEnabled(String category, String subcategory) {
    final path = '$category$_pathSeparator$subcategory';
    return _enabledPaths.contains(path);
  }

  /// Initializes the service.
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

    final adjCategoryIdMap = DeckParser.parseAdjectiveCategoriesCsv(
      adjCategoryCsv,
    );
    final nounCategoryIdMap = DeckParser.parseNounCategoriesCsv(
      nounCategoryCsv,
    );

    _allAdjectives = DeckParser.parseAdjectivesCsv(adjCsv, adjCategoryIdMap);
    _allNouns = DeckParser.parseNounsCsv(nounCsv, nounCategoryIdMap);

    _adjectiveCategories
      ..clear()
      ..addAll(adjCategoryIdMap.values);

    _nounCategoryMap.clear();
    for (final (category, subcategory) in nounCategoryIdMap.values) {
      _nounCategoryMap.putIfAbsent(category, () => <String>{}).add(subcategory);
    }

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

  /// Executes toggleAdjectiveCategory.
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

  /// Executes toggleNounSubcategory.
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

  /// Documents this public API member.
  List<CardModel> getActiveAdjectives() {
    final list = _allAdjectives
        .where((c) => _enabledPaths.contains(c.category))
        .toList();
    return list.isNotEmpty ? list : _allAdjectives.toList();
  }

  /// Documents this public API member.
  List<CardModel> getActiveNouns() {
    final list = _allNouns.where((c) {
      if (c.category == null) return false;
      final path = '${c.category}$_pathSeparator${c.subcategory}';
      return _enabledPaths.contains(path);
    }).toList();
    return list.isNotEmpty ? list : _allNouns.toList();
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
