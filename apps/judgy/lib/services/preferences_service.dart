import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] that owns the single async
/// initialisation.  All other services that need persistent key-value
/// storage depend on this rather than constructing their own instance.
class PreferencesService {
  /// Documents this public API member.
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  /// Documents this public API member.
  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // ── Read ──────────────────────────────────────────────────────────────

  /// Documents this public API member.
  String? getString(String key) => _prefs.getString(key);

  /// Documents this public API member.
  bool? getBool(String key) => _prefs.getBool(key);

  /// Documents this public API member.
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  // ── Write ─────────────────────────────────────────────────────────────

  /// Persists a string value by key.
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  /// Persists a boolean value by key.
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  /// Persists a string list value by key.
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  /// Removes a persisted value by key.
  Future<void> remove(String key) => _prefs.remove(key);
}
