import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight service for non-sensitive local UI preferences.
/// Strictly persists UI preferences (language, appearance) across app restarts.
/// NEVER store authentication tokens, credentials, PAN, Aadhaar, or session data here.
class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const String _keyLanguageCode = 'app_language_code';
  static const String _keyThemeMode = 'app_theme_mode';

  SharedPreferences? _prefs;
  final Map<String, String> _inMemoryFallback = {};

  @visibleForTesting
  void resetForTesting() {
    _prefs = null;
    _inMemoryFallback.clear();
  }

  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (_) {
      // In-memory fallback for test environments or restricted platforms
      return null;
    }
  }

  /// Loads saved language code ('en', 'hi', 'pa'). Returns null if unset or error.
  Future<String?> getSavedLanguageCode() async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        return prefs.getString(_keyLanguageCode);
      }
      return _inMemoryFallback[_keyLanguageCode];
    } catch (_) {
      return _inMemoryFallback[_keyLanguageCode];
    }
  }

  /// Persists language code.
  Future<void> saveLanguageCode(String code) async {
    _inMemoryFallback[_keyLanguageCode] = code;
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_keyLanguageCode, code);
    } catch (_) {}
  }

  /// Loads saved theme mode ('system', 'light', 'dark'). Returns null if unset or error.
  Future<String?> getSavedThemeMode() async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        return prefs.getString(_keyThemeMode);
      }
      return _inMemoryFallback[_keyThemeMode];
    } catch (_) {
      return _inMemoryFallback[_keyThemeMode];
    }
  }

  /// Persists theme mode name ('system', 'light', 'dark').
  Future<void> saveThemeMode(String mode) async {
    _inMemoryFallback[_keyThemeMode] = mode;
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_keyThemeMode, mode);
    } catch (_) {}
  }
}
