import 'package:flutter/material.dart';

/// Immutable model representing an Indian State or Union Territory
/// with canonical Indian state/UT code and reviewed native-language display names.
class IndianState {
  final String code;
  final String englishName;
  final String hindiName;
  final String punjabiName;

  const IndianState({
    required this.code,
    required this.englishName,
    required this.hindiName,
    required this.punjabiName,
  });

  /// Returns the localized display name for a given [Locale].
  /// Defaults to [englishName] for unsupported or English locales.
  String getLocalizedName(Locale? locale) {
    if (locale == null) return englishName;
    switch (locale.languageCode.toLowerCase()) {
      case 'hi':
        return hindiName;
      case 'pa':
        return punjabiName;
      default:
        return englishName;
    }
  }

  /// Returns the localized display name for a language code string (e.g. 'en', 'hi', 'pa').
  String getLocalizedNameForCode(String languageCode) {
    switch (languageCode.toLowerCase().trim()) {
      case 'hi':
        return hindiName;
      case 'pa':
        return punjabiName;
      default:
        return englishName;
    }
  }
}

/// Deterministic, offline dataset of all 36 Indian States and Union Territories.
/// No runtime AI or external translation service dependencies.
class IndianStates {
  IndianStates._();

  static const List<IndianState> allStates = [
    IndianState(
      code: 'AN',
      englishName: 'Andaman and Nicobar Islands',
      hindiName: 'अंडमान और निकोबार द्वीप समूह',
      punjabiName: 'ਅੰਡਮਾਨ ਅਤੇ ਨਿਕੋਬਾਰ ਦੀਪ ਸਮੂਹ',
    ),
    IndianState(
      code: 'AP',
      englishName: 'Andhra Pradesh',
      hindiName: 'आंध्र प्रदेश',
      punjabiName: 'ਆਂਧਰਾ ਪ੍ਰਦੇਸ਼',
    ),
    IndianState(
      code: 'AR',
      englishName: 'Arunachal Pradesh',
      hindiName: 'अरुणाचल प्रदेश',
      punjabiName: 'ਅਰੁਣਾਚਲ ਪ੍ਰਦੇਸ਼',
    ),
    IndianState(
      code: 'AS',
      englishName: 'Assam',
      hindiName: 'असम',
      punjabiName: 'ਅਸਾਮ',
    ),
    IndianState(
      code: 'BR',
      englishName: 'Bihar',
      hindiName: 'बिहार',
      punjabiName: 'ਬਿਹਾਰ',
    ),
    IndianState(
      code: 'CH',
      englishName: 'Chandigarh',
      hindiName: 'चंडीगढ़',
      punjabiName: 'ਚੰਡੀਗੜ੍ਹ',
    ),
    IndianState(
      code: 'CG',
      englishName: 'Chhattisgarh',
      hindiName: 'छत्तीसगढ़',
      punjabiName: 'ਛੱਤੀਸਗੜ੍ਹ',
    ),
    IndianState(
      code: 'DH',
      englishName: 'Dadra and Nagar Haveli and Daman and Diu',
      hindiName: 'दादरा और नगर हवेली और दमन और दीव',
      punjabiName: 'ਦਾਦਰਾ ਅਤੇ ਨਗਰ ਹਵੇਲੀ ਅਤੇ ਦਮਨ ਅਤੇ ਦੀਊ',
    ),
    IndianState(
      code: 'DL',
      englishName: 'Delhi',
      hindiName: 'दिल्ली',
      punjabiName: 'ਦਿੱਲੀ',
    ),
    IndianState(
      code: 'GA',
      englishName: 'Goa',
      hindiName: 'गोवा',
      punjabiName: 'ਗੋਆ',
    ),
    IndianState(
      code: 'GJ',
      englishName: 'Gujarat',
      hindiName: 'गुजरात',
      punjabiName: 'ਗੁਜਰਾਤ',
    ),
    IndianState(
      code: 'HR',
      englishName: 'Haryana',
      hindiName: 'हरियाणा',
      punjabiName: 'ਹਰਿਆਣਾ',
    ),
    IndianState(
      code: 'HP',
      englishName: 'Himachal Pradesh',
      hindiName: 'हिमाचल प्रदेश',
      punjabiName: 'ਹਿਮਾਚਲ ਪ੍ਰਦੇਸ਼',
    ),
    IndianState(
      code: 'JK',
      englishName: 'Jammu and Kashmir',
      hindiName: 'जम्मू और कश्मीर',
      punjabiName: 'ਜੰਮੂ ਅਤੇ ਕਸ਼ਮੀਰ',
    ),
    IndianState(
      code: 'JH',
      englishName: 'Jharkhand',
      hindiName: 'झारखंड',
      punjabiName: 'ਝਾਰਖੰਡ',
    ),
    IndianState(
      code: 'KA',
      englishName: 'Karnataka',
      hindiName: 'कर्नाटक',
      punjabiName: 'ਕਰਨਾਟਕ',
    ),
    IndianState(
      code: 'KL',
      englishName: 'Kerala',
      hindiName: 'केरल',
      punjabiName: 'ਕੇਰਲ',
    ),
    IndianState(
      code: 'LA',
      englishName: 'Ladakh',
      hindiName: 'लद्दाख',
      punjabiName: 'ਲੱਦਾਖ',
    ),
    IndianState(
      code: 'LD',
      englishName: 'Lakshadweep',
      hindiName: 'लक्षद्वीप',
      punjabiName: 'ਲਕਸ਼ਦੀਪ',
    ),
    IndianState(
      code: 'MP',
      englishName: 'Madhya Pradesh',
      hindiName: 'मध्य प्रदेश',
      punjabiName: 'ਮੱਧ ਪ੍ਰਦੇਸ਼',
    ),
    IndianState(
      code: 'MH',
      englishName: 'Maharashtra',
      hindiName: 'महाराष्ट्र',
      punjabiName: 'ਮਹਾਰਾਸ਼ਟਰ',
    ),
    IndianState(
      code: 'MN',
      englishName: 'Manipur',
      hindiName: 'मणिपुर',
      punjabiName: 'ਮਣੀਪੁਰ',
    ),
    IndianState(
      code: 'ML',
      englishName: 'Meghalaya',
      hindiName: 'मेघालय',
      punjabiName: 'ਮੇਘਾਲਿਆ',
    ),
    IndianState(
      code: 'MZ',
      englishName: 'Mizoram',
      hindiName: 'मिज़ोरम',
      punjabiName: 'ਮਿਜ਼ੋਰਮ',
    ),
    IndianState(
      code: 'NL',
      englishName: 'Nagaland',
      hindiName: 'नागालैंड',
      punjabiName: 'ਨਾਗਾਲੈਂਡ',
    ),
    IndianState(
      code: 'OD',
      englishName: 'Odisha',
      hindiName: 'ओडिशा',
      punjabiName: 'ਓਡੀਸ਼ਾ',
    ),
    IndianState(
      code: 'PY',
      englishName: 'Puducherry',
      hindiName: 'पुडुचेरी',
      punjabiName: 'ਪੁਡੂਚੇਰੀ',
    ),
    IndianState(
      code: 'PB',
      englishName: 'Punjab',
      hindiName: 'पंजाब',
      punjabiName: 'ਪੰਜਾਬ',
    ),
    IndianState(
      code: 'RJ',
      englishName: 'Rajasthan',
      hindiName: 'राजस्थान',
      punjabiName: 'ਰਾਜਸਥਾਨ',
    ),
    IndianState(
      code: 'SK',
      englishName: 'Sikkim',
      hindiName: 'सिक्किम',
      punjabiName: 'ਸਿੱਕਮ',
    ),
    IndianState(
      code: 'TN',
      englishName: 'Tamil Nadu',
      hindiName: 'तमिलनाडु',
      punjabiName: 'ਤਾਮਿਲਨਾਡੂ',
    ),
    IndianState(
      code: 'TS',
      englishName: 'Telangana',
      hindiName: 'तेलंगाना',
      punjabiName: 'ਤੇਲੰਗਾਨਾ',
    ),
    IndianState(
      code: 'TR',
      englishName: 'Tripura',
      hindiName: 'त्रिपुरा',
      punjabiName: 'ਤ੍ਰਿਪੁਰਾ',
    ),
    IndianState(
      code: 'UP',
      englishName: 'Uttar Pradesh',
      hindiName: 'उत्तर प्रदेश',
      punjabiName: 'ਉੱਤਰ ਪ੍ਰਦੇਸ਼',
    ),
    IndianState(
      code: 'UK',
      englishName: 'Uttarakhand',
      hindiName: 'उत्तराखंड',
      punjabiName: 'ਉੱਤਰਾਖੰਡ',
    ),
    IndianState(
      code: 'WB',
      englishName: 'West Bengal',
      hindiName: 'पश्चिम बंगाल',
      punjabiName: 'ਪੱਛਮੀ ਬੰਗਾਲ',
    ),
  ];

  /// Look up an [IndianState] by its canonical Indian state/UT code (case-insensitive).
  static IndianState? findByCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.trim().toUpperCase();
    for (final state in allStates) {
      if (state.code == normalized) return state;
    }
    return null;
  }

  /// Look up an [IndianState] by any of its display names (English, Hindi, Punjabi) or code.
  static IndianState? findByCodeOrName(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim();
    final upper = normalized.toUpperCase();

    for (final state in allStates) {
      if (state.code == upper ||
          state.englishName.toLowerCase() == normalized.toLowerCase() ||
          state.hindiName == normalized ||
          state.punjabiName == normalized) {
        return state;
      }
    }
    return null;
  }

  /// Resolves the canonical Indian state/UT code for a given state code or display name.
  /// If unknown, returns the trimmed original input string.
  static String getCanonicalCode(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return findByCodeOrName(value)?.code ?? value.trim();
  }

  /// Returns the localized display name for a code or name given a [Locale].
  /// Returns the trimmed input if not found.
  static String getLocalizedName(String? codeOrName, Locale? locale) {
    if (codeOrName == null || codeOrName.trim().isEmpty) return '';
    final state = findByCodeOrName(codeOrName);
    return state != null ? state.getLocalizedName(locale) : codeOrName.trim();
  }

  /// Returns the English display name for a code or name.
  static String getEnglishName(String? codeOrName) {
    if (codeOrName == null || codeOrName.trim().isEmpty) return '';
    final state = findByCodeOrName(codeOrName);
    return state != null ? state.englishName : codeOrName.trim();
  }
}
