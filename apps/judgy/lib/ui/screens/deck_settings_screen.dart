import 'package:flutter/material.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:provider/provider.dart';

/// A comprehensive settings screen for managing card deck categories.
///
/// Shows adjective categories and noun categories with subcategories,
/// allowing users to enable/disable them individually or by group.
class DeckSettingsScreen extends StatefulWidget {
  const DeckSettingsScreen({super.key});

  @override
  State<DeckSettingsScreen> createState() => _DeckSettingsScreenState();
}

class _DeckSettingsScreenState extends State<DeckSettingsScreen> {
  late Map<String, bool> adjectiveStatus;
  late Map<String, Map<String, bool>> nounStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deckService = context.watch<DeckService>();
    adjectiveStatus = deckService.getAdjectiveStatus();
    nounStatus = deckService.getNounStatus();
  }

  void _toggleAdjectiveCategory(String category, bool? value) {
    if (value == null) return;
    context.read<DeckService>().toggleAdjectiveCategory(
      category,
      isEnabled: value,
    );
  }

  void _toggleNounSubcategory(
    String category,
    String subcategory,
    bool? value,
  ) {
    if (value == null) return;
    context.read<DeckService>().toggleNounSubcategory(
      category,
      subcategory,
      isEnabled: value,
    );
  }

  void _toggleCategoryGroup(String category, bool shouldEnable) {
    final deckService = context.read<DeckService>();
    if (nounStatus.containsKey(category)) {
      // Toggle all subcategories in this noun category
      for (final subcategory in nounStatus[category]!.keys) {
        deckService.toggleNounSubcategory(
          category,
          subcategory,
          isEnabled: shouldEnable,
        );
      }
    }
  }

  bool _isCategoryGroupFullyEnabled(String category) {
    if (nounStatus.containsKey(category)) {
      return nounStatus[category]!.values.every((v) => v);
    }
    return adjectiveStatus[category] ?? false;
  }

  bool _isCategoryGroupPartiallyEnabled(String category) {
    if (nounStatus.containsKey(category)) {
      final values = nounStatus[category]!.values;
      final enabled = values.where((v) => v).length;
      return enabled > 0 && enabled < values.length;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deckService = context.watch<DeckService>();

    if (!deckService.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Deck Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ── Adjectives Section ──────────────────────────
          _CategorySection(
            title: 'Adjectives',
            icon: Icons.emoji_emotions,
            theme: theme,
            children: [
              for (final category
                  in deckService.adjectiveCategories.toList()..sort())
                _CategoryTile(
                  title: category,
                  isEnabled: _isCategoryGroupFullyEnabled(category),
                  isPartial: false,
                  onChanged: (value) =>
                      _toggleAdjectiveCategory(category, value),
                ),
            ],
          ),

          const Divider(),

          // ── Nouns Section ─────────────────────────────
          _CategorySection(
            title: 'Nouns',
            icon: Icons.category,
            theme: theme,
            children: [
              for (final category
                  in deckService.nounCategoryMap.keys.toList()..sort())
                _NounCategoryGroup(
                  category: category,
                  subcategories: deckService.nounCategoryMap[category]!.toList()
                    ..sort(),
                  subCategoryStatus: nounStatus[category] ?? {},
                  isCategoryFullyEnabled: _isCategoryGroupFullyEnabled(
                    category,
                  ),
                  isCategoryPartiallyEnabled: _isCategoryGroupPartiallyEnabled(
                    category,
                  ),
                  onSubcategoryToggle: (subcategory, {required isEnabled}) =>
                      _toggleNounSubcategory(
                        category,
                        subcategory,
                        isEnabled,
                      ),
                  onGroupToggle: ({required isEnabled}) =>
                      _toggleCategoryGroup(category, isEnabled),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A section header for grouping categories by type.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.icon,
    required this.theme,
    required this.children,
  });

  final String title;
  final IconData icon;
  final ThemeData theme;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

/// A tile for toggling a single category.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.isEnabled,
    required this.isPartial,
    required this.onChanged,
  });

  final String title;
  final bool isEnabled;
  final bool isPartial;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(title),
      value: isEnabled,
      tristate: isPartial,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

/// A group of noun categories with their subcategories.
///
/// This section is always expanded to avoid accidental toggles when users
/// are trying to reveal nested items.
class _NounCategoryGroup extends StatelessWidget {
  const _NounCategoryGroup({
    required this.category,
    required this.subcategories,
    required this.subCategoryStatus,
    required this.isCategoryFullyEnabled,
    required this.isCategoryPartiallyEnabled,
    required this.onSubcategoryToggle,
    required this.onGroupToggle,
  });

  final String category;
  final List<String> subcategories;
  final Map<String, bool> subCategoryStatus;
  final bool isCategoryFullyEnabled;
  final bool isCategoryPartiallyEnabled;
  final void Function(String, {required bool isEnabled}) onSubcategoryToggle;
  final void Function({required bool isEnabled}) onGroupToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Category header (always expanded)
        ColoredBox(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          child: CheckboxListTile(
            title: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            value: isCategoryFullyEnabled,
            tristate: isCategoryPartiallyEnabled,
            onChanged: (value) {
              if (value != null) {
                onGroupToggle(isEnabled: value);
              }
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        // Always-show subcategories
        ColoredBox(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.05),
          child: Column(
            children: [
              for (final subcategory in subcategories)
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: CheckboxListTile(
                    title: Text(
                      subcategory,
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: subCategoryStatus[subcategory] ?? false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        onSubcategoryToggle(
                          subcategory,
                          isEnabled: value,
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
