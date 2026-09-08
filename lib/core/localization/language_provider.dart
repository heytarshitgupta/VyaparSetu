import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// Supported visible application languages.
enum AppLanguage {
  english(Locale('en'), 'English', 'English'),
  hindi(Locale('hi'), 'हिन्दी', 'Hindi'),
  punjabi(Locale('pa'), 'ਪੰਜਾਬੀ', 'Punjabi');

  final Locale locale;
  final String nativeLabel;
  final String englishLabel;

  const AppLanguage(this.locale, this.nativeLabel, this.englishLabel);

  static AppLanguage fromLocale(Locale locale) {
    for (final lang in AppLanguage.values) {
      if (lang.locale.languageCode == locale.languageCode) {
        return lang;
      }
    }
    return AppLanguage.english; // Fallback to English
  }

  static AppLanguage fromCode(String code) {
    for (final lang in AppLanguage.values) {
      if (lang.locale.languageCode == code.toLowerCase().trim()) {
        return lang;
      }
    }
    return AppLanguage.english;
  }
}

/// Supported options for voice guidance language.
enum VoiceGuidanceOption {
  sameAsApp('sameasapp', 'Same as App Language'),
  english('en', 'English'),
  hindi('hi', 'हिन्दी'),
  punjabi('pa', 'ਪੰਜਾਬੀ');

  final String code;
  final String label;
  const VoiceGuidanceOption(this.code, this.label);

  static VoiceGuidanceOption fromCode(String? code) {
    if (code == null) return VoiceGuidanceOption.sameAsApp;
    final normalized = code.trim().toLowerCase();
    for (final opt in VoiceGuidanceOption.values) {
      if (opt.code == normalized) return opt;
    }
    return VoiceGuidanceOption.sameAsApp;
  }
}

/// Independent voice guidance language for future spoken instructions / TTS.
/// Kept architecturally decoupled from visible [AppLanguage].
enum VoiceLanguage {
  english('en-IN', 'English (India)', 'English'),
  hindi('hi-IN', 'हिन्दी (भारत)', 'Hindi'),
  punjabi('pa-IN', 'ਪੰਜਾਬੀ (ਭਾਰਤ)', 'Punjabi');

  final String bcp47Code;
  final String nativeLabel;
  final String englishLabel;

  const VoiceLanguage(this.bcp47Code, this.nativeLabel, this.englishLabel);
}

/// Shared language state for the application.
class LanguageProvider extends ChangeNotifier {
  AppLanguage _appLanguage = AppLanguage.english;
  VoiceLanguage _voiceLanguage = VoiceLanguage.hindi;
  VoiceGuidanceOption _voiceGuidanceOption = VoiceGuidanceOption.sameAsApp;
  final PreferencesService _prefs = PreferencesService.instance;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  AppLanguage get appLanguage => _appLanguage;
  Locale get currentLocale => _appLanguage.locale;
  VoiceLanguage get voiceLanguage => _voiceLanguage;
  VoiceGuidanceOption get voiceGuidanceOption => _voiceGuidanceOption;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('pa'),
  ];

  Future<void> _loadSavedLanguage() async {
    final savedCode = await _prefs.getSavedLanguageCode();
    if (savedCode != null) {
      final lang = AppLanguage.fromCode(savedCode);
      if (_appLanguage != lang) {
        _appLanguage = lang;
      }
    }
    final savedVoice = await _prefs.getSavedVoiceLanguageOption();
    if (savedVoice != null) {
      _voiceGuidanceOption = VoiceGuidanceOption.fromCode(savedVoice);
    }
    notifyListeners();
  }

  /// Changes the visible application language and persists preference.
  void setAppLanguage(AppLanguage language) {
    if (_appLanguage != language) {
      _appLanguage = language;
      notifyListeners();
      _prefs.saveLanguageCode(language.locale.languageCode);
    }
  }

  /// Sets locale directly, falling back to English if unsupported.
  void setLocale(Locale locale) {
    setAppLanguage(AppLanguage.fromLocale(locale));
  }

  /// Sets the voice guidance option and persists preference.
  void setVoiceGuidanceOption(VoiceGuidanceOption option) {
    if (_voiceGuidanceOption != option) {
      _voiceGuidanceOption = option;
      _syncVoiceOption(option);
      notifyListeners();
      _prefs.saveVoiceLanguageOption(option.code);
    }
  }

  void _syncVoiceToAppLanguage() {
    switch (_appLanguage) {
      case AppLanguage.english:
        _voiceLanguage = VoiceLanguage.english;
        break;
      case AppLanguage.hindi:
        _voiceLanguage = VoiceLanguage.hindi;
        break;
      case AppLanguage.punjabi:
        _voiceLanguage = VoiceLanguage.punjabi;
        break;
    }
  }

  void _syncVoiceOption(VoiceGuidanceOption option) {
    switch (option) {
      case VoiceGuidanceOption.english:
        _voiceLanguage = VoiceLanguage.english;
        break;
      case VoiceGuidanceOption.hindi:
        _voiceLanguage = VoiceLanguage.hindi;
        break;
      case VoiceGuidanceOption.punjabi:
        _voiceLanguage = VoiceLanguage.punjabi;
        break;
      case VoiceGuidanceOption.sameAsApp:
        _syncVoiceToAppLanguage();
        break;
    }
  }

  /// Sets the voice guidance language independently without altering [appLanguage].
  void setVoiceLanguage(VoiceLanguage language) {
    if (_voiceLanguage != language) {
      _voiceLanguage = language;
      notifyListeners();
    }
  }
}
