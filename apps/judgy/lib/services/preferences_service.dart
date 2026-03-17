import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] that owns the single async
/// initialisation.  All other services that need persistent key-value
/// storage depend on this rather than constructing their own instance.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // ── Read ──────────────────────────────────────────────────────────────

  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);

  // ── Write ─────────────────────────────────────────────────────────────

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
}
