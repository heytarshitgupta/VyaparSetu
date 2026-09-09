import 'package:flutter/foundation.dart';

/// Manages strictly in-memory session state for business verification UI.
///
/// Banner dismissal is never persisted to database, SharedPreferences,
/// secure storage, or profile fields.
class BusinessVerificationSession {
  BusinessVerificationSession._();

  static final BusinessVerificationSession instance =
      BusinessVerificationSession._();

  bool _isHomeBannerDismissed = false;

  /// Whether the Home verification banner has been dismissed in the current app session.
  bool get isHomeBannerDismissed => _isHomeBannerDismissed;

  /// Dismisses the Home verification banner for the duration of the current app session.
  void dismissHomeBanner() {
    _isHomeBannerDismissed = true;
  }

  /// Resets session-only state. Strictly for testing or fresh-session simulation.
  @visibleForTesting
  void reset() {
    _isHomeBannerDismissed = false;
  }
}
