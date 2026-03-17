import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:judgy/services/consent_service.dart';

/// Wraps Firebase Analytics and silently drops events when the user has not
/// given consent.  All calls are fire-and-forget.
class AnalyticsService {
  AnalyticsService(this._consentService);

  final ConsentService _consentService;

  /// Logs a named event with optional parameters.
  /// Does nothing if Firebase is unavailable or consent has not been given.
  void logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    try {
      if (Firebase.apps.isEmpty || !_consentService.analyticsAllowed) return;

      // TODO(bramp): Return the future, and let the caller decide if they want to await it or not.
      unawaited(
        FirebaseAnalytics.instance.logEvent(
          name: name,
          parameters: parameters,
        ),
      );
    } on Object catch (e) {
      debugPrint('AnalyticsService: $e');
    }
  }
}
