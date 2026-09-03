import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/localization/generated/app_localizations.dart';
import 'core/localization/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routes/app_router.dart';
import 'buyer_section/onboarding/buyer_profile_provider.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BuyerProfileProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const VyaparSetuApp(),
    ),
  );
}

class VyaparSetuApp extends StatelessWidget {
  const VyaparSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    LanguageProvider? languageProvider;
    try {
      languageProvider = Provider.of<LanguageProvider>(context);
    } catch (_) {
      // Fallback for isolated test harnesses without LanguageProvider
    }
    final currentLocale = languageProvider?.currentLocale ?? const Locale('en');

    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context);
    } catch (_) {
      // Fallback for isolated test harnesses without ThemeProvider
    }
    final currentThemeMode = themeProvider?.themeMode ?? ThemeMode.system;

    return MaterialApp(
      title: 'VyaparSetu Buyer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
