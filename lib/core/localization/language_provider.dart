import 'package:flutter/material.dart';

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
  VoiceLanguage _voiceLanguage = VoiceLanguage.hindi; // Independent default for future voice guidance

  AppLanguage get appLanguage => _appLanguage;
  Locale get currentLocale => _appLanguage.locale;
  VoiceLanguage get voiceLanguage => _voiceLanguage;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('pa'),
  ];

  /// Changes the visible application language.
  void setAppLanguage(AppLanguage language) {
    if (_appLanguage != language) {
      _appLanguage = language;
      notifyListeners();
    }
  }

  /// Sets locale directly, falling back to English if unsupported.
  void setLocale(Locale locale) {
    setAppLanguage(AppLanguage.fromLocale(locale));
  }

  /// Sets the voice guidance language independently without altering [appLanguage].
  void setVoiceLanguage(VoiceLanguage language) {
    if (_voiceLanguage != language) {
      _voiceLanguage = language;
      notifyListeners();
    }
  }
}
