import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:judgy/models/game_models.dart';
import 'package:judgy/services/preferences_service.dart';

class DeckService extends ChangeNotifier {
  DeckService(this._preferencesService);

  final PreferencesService _preferencesService;

  static const String _categoriesKey = 'enabled_categories';

  List<CardModel> _allAdjectives = [];
  List<CardModel> _allNouns = [];

  Set<String> _availableCategories = {};
  Set<String> _enabledCategories = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Set<String> get availableCategories => _availableCategories;
  Set<String> get enabledCategories => _enabledCategories;

  Future<void> init() async {
    if (_isInitialized) return;

    final adjCsv = await rootBundle.loadString('assets/data/adjectives.csv');
    final nounCsv = await rootBundle.loadString('assets/data/nouns.csv');

    _allAdjectives = _parseCsv(adjCsv, CardType.adjective);
    _allNouns = _parseCsv(nounCsv, CardType.noun);

    final categories = <String>{};
    for (final card in _allAdjectives) {
      if (card.category != null) categories.add(card.category!);
    }
    for (final card in _allNouns) {
      if (card.category != null) categories.add(card.category!);
    }
    _availableCategories = categories.toSet()
      // sort set alphabetically if needed, but keeping it as unmodifiable
      ..toList().sort();

    final saved = _preferencesService.getStringList(_categoriesKey);
    if (saved != null) {
      _enabledCategories = saved
          .where((c) => _availableCategories.contains(c))
          .toSet();
      // If none matched, fallback to all
      if (_enabledCategories.isEmpty) {
        _enabledCategories = Set.from(_availableCategories);
      }
    } else {
      // By default enable all
      _enabledCategories = Set.from(_availableCategories);
    }

    _isInitialized = true;
    notifyListeners();
  }

  void toggleCategory(String category, {required bool isEnabled}) {
    if (isEnabled) {
      _enabledCategories.add(category);
    } else {
      // Prevent disabling the very last category
      if (_enabledCategories.length <= 1 &&
          _enabledCategories.contains(category)) {
        return;
      }
      _enabledCategories.remove(category);
    }
    _preferencesService.setStringList(
      _categoriesKey,
      _enabledCategories.toList(),
    );
    notifyListeners();
  }

  List<CardModel> getActiveAdjectives() {
    final list = _allAdjectives
        .where((c) => _enabledCategories.contains(c.category))
        .toList();
    // fallback if somehow empty
    return list.isNotEmpty ? list : _allAdjectives.toList();
  }

  List<CardModel> getActiveNouns() {
    final list = _allNouns
        .where((c) => _enabledCategories.contains(c.category))
        .toList();
    // fallback if somehow empty
    return list.isNotEmpty ? list : _allNouns.toList();
  }

  List<CardModel> _parseCsv(String csvString, CardType type) {
    final rows = const CsvDecoder().convert(csvString).skip(1);
    final cards = <CardModel>[];
    int idCounter = 1;
    for (final row in rows) {
      if (row.isEmpty) continue;

      final category = row.isNotEmpty ? row[0].toString().trim() : null;
      final isNoun = type == CardType.noun;
      final textIndex = isNoun ? 2 : 1;

      if (row.length > textIndex) {
        final text = row[textIndex].toString().trim();
        if (text.isNotEmpty) {
          cards.add(
            CardModel(
              id: '\${type.name}_\${category?.hashCode ?? 0}_${idCounter++}',
              text: text,
              type: type,
              category: category,
            ),
          );
        }
      }
    }
    return cards;
  }
}
