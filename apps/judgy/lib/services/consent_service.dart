import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:judgy/services/preferences_service.dart';

/// Tracks whether the user has given consent for analytics collection.
///
/// Local storage for game progress (saves, unlocks) is treated as strictly
/// necessary and does not require consent.  Analytics (Firebase) is optional
/// and requires an explicit opt-in.
class ConsentService extends ChangeNotifier {
  ConsentService(this._prefs, {this.debugOverride = kDebugMode}) {
    _analyticsConsent = _prefs.getBool(_keyAnalyticsConsent);

    // Apply the stored preference to Firebase immediately.
    _applyToFirebase();
  }

  final PreferencesService _prefs;

  /// Whether to override consent in debug mode.
  final bool debugOverride;

  static const String _keyAnalyticsConsent = 'analytics_consent';

  /// `null` = not yet asked, `true` = accepted, `false` = declined.
  bool? _analyticsConsent;

  /// Whether the consent banner still needs to be shown.
  bool get needsConsent {
    if (debugOverride) return false;
    return _analyticsConsent == null;
  }

  /// Whether analytics collection is currently allowed.
  bool get analyticsAllowed {
    if (debugOverride) return true;
    return _analyticsConsent == true;
  }

  /// Record the user's choice and persist it.
  Future<void> setAnalyticsConsent({required bool allowed}) async {
    _analyticsConsent = allowed;
    await _prefs.setBool(_keyAnalyticsConsent, value: allowed);
    _applyToFirebase();
    notifyListeners();
  }

  void _applyToFirebase() {
    try {
      if (Firebase.apps.isNotEmpty) {
        unawaited(
          FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
            _analyticsConsent == true,
          ),
        );
      }
    } on Object catch (e) {
      debugPrint('ConsentService: Firebase error: $e');
    }
  }
}
