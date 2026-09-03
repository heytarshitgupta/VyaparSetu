import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/producer_section/localization/widgets/language_switcher_widget.dart';

void main() {
  group('Localization Foundation Tests', () {
    test('English translations load correctly with all foundational strings', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(l10n.localeName, 'en');
      expect(l10n.home, 'Home');
      expect(l10n.myProducts, 'My Products');
      expect(l10n.addProduct, 'Add Product');
      expect(l10n.buyerNeeds, 'Buyer Needs');
      expect(l10n.whatBuyersWant, 'What Buyers Want');
      expect(l10n.myProfile, 'My Profile');
      expect(l10n.settings, 'Settings');
      expect(l10n.welcome, 'Welcome');
      expect(l10n.continueButton, 'Continue');
      expect(l10n.back, 'Back');
      expect(l10n.save, 'Save');
      expect(l10n.cancel, 'Cancel');
      expect(l10n.verify, 'Verify');
      expect(l10n.verified, 'Verified');
      expect(l10n.notVerified, 'Not Verified');
    });

    test('Hindi translations load correctly in Devanagari script', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('hi'));

      expect(l10n.localeName, 'hi');
      expect(l10n.home, 'होम');
      expect(l10n.myProducts, 'मेरे उत्पाद');
      expect(l10n.addProduct, 'उत्पाद जोड़ें');
      expect(l10n.buyerNeeds, 'खरीदारों की जरूरतें');
      expect(l10n.whatBuyersWant, 'खरीदार क्या चाहते हैं');
      expect(l10n.myProfile, 'मेरी प्रोफाइल');
      expect(l10n.settings, 'सेटिंग्स');
      expect(l10n.welcome, 'स्वागत है');
      expect(l10n.continueButton, 'आगे बढ़ें');
      expect(l10n.back, 'पीछे जाएं');
      expect(l10n.save, 'सहेजें');
      expect(l10n.cancel, 'रद्द करें');
      expect(l10n.verify, 'सत्यापित करें');
      expect(l10n.verified, 'सत्यापित');
      expect(l10n.notVerified, 'सत्यापित नहीं');
    });

    test('Punjabi translations load correctly in Gurmukhi script', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('pa'));

      expect(l10n.localeName, 'pa');
      expect(l10n.home, 'ਹੋਮ');
      expect(l10n.myProducts, 'ਮੇਰੇ ਉਤਪਾਦ');
      expect(l10n.addProduct, 'ਉਤਪਾਦ ਸ਼ਾਮਲ ਕਰੋ');
      expect(l10n.buyerNeeds, 'ਖਰੀਦਦਾਰਾਂ ਦੀਆਂ ਲੋੜਾਂ');
      expect(l10n.whatBuyersWant, 'ਖਰੀਦਦਾਰ ਕੀ ਚਾਹੁੰਦੇ ਹਨ');
      expect(l10n.myProfile, 'ਮੇਰੀ ਪ੍ਰੋਫਾਈਲ');
      expect(l10n.settings, 'ਸੈਟਿੰਗਾਂ');
      expect(l10n.welcome, 'ਜੀ ਆਇਆਂ ਨੂੰ');
      expect(l10n.continueButton, 'ਅੱਗੇ ਵਧੋ');
      expect(l10n.back, 'ਪਿੱਛੇ ਜਾਓ');
      expect(l10n.save, 'ਸੰਭਾਲੋ');
      expect(l10n.cancel, 'ਰੱਦ ਕਰੋ');
      expect(l10n.verify, 'ਤਸਦੀਕ ਕਰੋ');
      expect(l10n.verified, 'ਤਸਦੀਕਸ਼ੁਦਾ');
      expect(l10n.notVerified, 'ਤਸਦੀਕ ਨਹੀਂ ਹੋਇਆ');
    });

    test('LanguageProvider defaults to English and safely falls back for unsupported locales', () {
      final provider = LanguageProvider();
      expect(provider.appLanguage, AppLanguage.english);
      expect(provider.currentLocale, const Locale('en'));

      // Test unsupported locale fallback
      provider.setLocale(const Locale('fr'));
      expect(provider.appLanguage, AppLanguage.english);
      expect(provider.currentLocale, const Locale('en'));

      // Test valid locale changes
      provider.setLocale(const Locale('hi'));
      expect(provider.appLanguage, AppLanguage.hindi);
      expect(provider.currentLocale, const Locale('hi'));

      provider.setLocale(const Locale('pa'));
      expect(provider.appLanguage, AppLanguage.punjabi);
      expect(provider.currentLocale, const Locale('pa'));
    });

    test('App Language and Voice Guidance Language are strictly decoupled', () {
      final provider = LanguageProvider();

      // Initial state
      expect(provider.appLanguage, AppLanguage.english);
      expect(provider.voiceLanguage, VoiceLanguage.hindi);

      // Changing voice language does NOT change appLanguage or currentLocale
      provider.setVoiceLanguage(VoiceLanguage.punjabi);
      expect(provider.voiceLanguage, VoiceLanguage.punjabi);
      expect(provider.appLanguage, AppLanguage.english);
      expect(provider.currentLocale, const Locale('en'));

      // Changing app language does NOT change voiceLanguage
      provider.setAppLanguage(AppLanguage.hindi);
      expect(provider.appLanguage, AppLanguage.hindi);
      expect(provider.currentLocale, const Locale('hi'));
      expect(provider.voiceLanguage, VoiceLanguage.punjabi); // Remains Punjabi
    });

    testWidgets('Live UI locale switching updates visible localized text immediately', (WidgetTester tester) async {
      final languageProvider = LanguageProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
          child: Consumer<LanguageProvider>(
            builder: (context, lang, _) {
              return MaterialApp(
                locale: lang.currentLocale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(
                          builder: (innerContext) {
                            final l10n = AppLocalizations.of(innerContext)!;
                            return Text(
                              l10n.welcome,
                              key: const Key('localized_welcome_text'),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const LanguageSwitcherWidget(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initially English: "Welcome"
      expect(find.text('Welcome'), findsOneWidget);

      // 2. Open Language Switcher bottom sheet
      final switcherButton = find.byKey(const Key('language_switcher_button'));
      expect(switcherButton, findsOneWidget);
      await tester.tap(switcherButton);
      await tester.pumpAndSettle();

      // Verify all options displayed clearly
      expect(find.text('English'), findsWidgets);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('ਪੰਜਾਬੀ'), findsOneWidget);

      // 3. Switch to Hindi
      final hindiOption = find.byKey(const Key('language_option_hi'));
      await tester.tap(hindiOption);
      await tester.pumpAndSettle();

      // Visible text updates to Hindi: "स्वागत है"
      expect(find.text('स्वागत है'), findsOneWidget);
      expect(find.text('Welcome'), findsNothing);

      // 4. Switch to Punjabi
      await tester.tap(switcherButton);
      await tester.pumpAndSettle();

      final punjabiOption = find.byKey(const Key('language_option_pa'));
      await tester.tap(punjabiOption);
      await tester.pumpAndSettle();

      // Visible text updates to Punjabi: "ਜੀ ਆਇਆਂ ਨੂੰ"
      expect(find.text('ਜੀ ਆਇਆਂ ਨੂੰ'), findsOneWidget);
      expect(find.text('स्वागत है'), findsNothing);
      expect(find.text('Welcome'), findsNothing);
    });
  });
}
