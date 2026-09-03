import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// Supported appearance options for UI presentation.
enum AppThemeOption {
  system(ThemeMode.system, 'system'),
  light(ThemeMode.light, 'light'),
  dark(ThemeMode.dark, 'dark');

  final ThemeMode mode;
  final String keyName;

  const AppThemeOption(this.mode, this.keyName);

  static AppThemeOption fromString(String? value) {
    if (value == null) return AppThemeOption.system;
    switch (value.toLowerCase().trim()) {
      case 'light':
        return AppThemeOption.light;
      case 'dark':
        return AppThemeOption.dark;
      case 'system':
      default:
        return AppThemeOption.system;
    }
  }
}

/// Shared appearance state for application theme mode.
/// Completely decoupled from authentication, credentials, App Language, and Voice Language.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeOption _themeOption = AppThemeOption.system;
  final PreferencesService _prefs = PreferencesService.instance;

  ThemeProvider() {
    _loadSavedTheme();
  }

  ThemeMode get themeMode => _themeMode;
  AppThemeOption get themeOption => _themeOption;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  Future<void> _loadSavedTheme() async {
    final savedMode = await _prefs.getSavedThemeMode();
    if (savedMode != null) {
      final option = AppThemeOption.fromString(savedMode);
      if (_themeOption != option) {
        _themeOption = option;
        _themeMode = option.mode;
        notifyListeners();
      }
    }
  }

  /// Sets the active theme option and persists the choice.
  void setThemeOption(AppThemeOption option) {
    if (_themeOption != option) {
      _themeOption = option;
      _themeMode = option.mode;
      notifyListeners();
      _prefs.saveThemeMode(option.keyName);
    }
  }

  /// Convenience helper to set ThemeMode directly.
  void setThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        setThemeOption(AppThemeOption.light);
        break;
      case ThemeMode.dark:
        setThemeOption(AppThemeOption.dark);
        break;
      case ThemeMode.system:
        setThemeOption(AppThemeOption.system);
        break;
    }
  }
}
