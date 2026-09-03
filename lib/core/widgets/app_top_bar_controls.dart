import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/generated/app_localizations.dart';
import '../localization/language_provider.dart';
import '../theme/theme_provider.dart';

/// Reusable pre-login top-bar controls for Language and Appearance.
/// Compact, accessible, and works seamlessly across welcome, login, signup, and settings.
class AppTopBarControls extends StatelessWidget {
  final bool showLabels;

  const AppTopBarControls({
    super.key,
    this.showLabels = true,
  });

  void _showLanguageSheet(BuildContext context) {
    LanguageProvider? languageProvider;
    try {
      languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    } catch (_) {}

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      builder: (sheetContext) {
        final current = languageProvider?.appLanguage ?? AppLanguage.english;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.language, size: 22, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n?.language ?? 'Language / भाषा / ਭਾਸ਼ਾ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...AppLanguage.values.map((lang) {
                  final isSelected = lang == current;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          key: Key('app_top_bar_lang_${lang.locale.languageCode}'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            lang.nativeLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            lang.englishLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
                              : null,
                          onTap: () {
                            languageProvider?.setAppLanguage(lang);
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeSheet(BuildContext context) {
    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    } catch (_) {}

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      builder: (sheetContext) {
        final currentOption = themeProvider?.themeOption ?? AppThemeOption.system;
        final sheetL10n = AppLocalizations.of(sheetContext) ?? l10n;

        final options = [
          (
            AppThemeOption.light,
            Icons.wb_sunny_outlined,
            sheetL10n?.themeLight ?? 'Light',
            'app_top_bar_theme_light',
          ),
          (
            AppThemeOption.dark,
            Icons.nightlight_outlined,
            sheetL10n?.themeDark ?? 'Dark',
            'app_top_bar_theme_dark',
          ),
          (
            AppThemeOption.system,
            Icons.smartphone_outlined,
            sheetL10n?.themeSystem ?? 'Use phone setting',
            'app_top_bar_theme_system',
          ),
        ];

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 22, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sheetL10n?.chooseAppearance ?? 'Choose appearance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...options.map((item) {
                  final (opt, iconData, title, testKey) = item;
                  final isSelected = opt == currentOption;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          key: Key(testKey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Icon(
                            iconData,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            size: 22,
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
                              : null,
                          onTap: () {
                            themeProvider?.setThemeOption(opt);
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    LanguageProvider? languageProvider;
    try {
      languageProvider = Provider.of<LanguageProvider>(context);
    } catch (_) {}
    final currentLang = languageProvider?.appLanguage ?? AppLanguage.english;

    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context);
    } catch (_) {}
    final currentTheme = themeProvider?.themeOption ?? AppThemeOption.system;

    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;
    final surfaceColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    IconData themeIcon;
    switch (currentTheme) {
      case AppThemeOption.light:
        themeIcon = Icons.wb_sunny_outlined;
        break;
      case AppThemeOption.dark:
        themeIcon = Icons.nightlight_outlined;
        break;
      case AppThemeOption.system:
        themeIcon = Icons.brightness_auto_outlined;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language Button
        Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: const Key('app_top_bar_language_button'),
            onTap: () => _showLanguageSheet(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 18, color: theme.colorScheme.primary),
                  if (showLabels) ...[
                    const SizedBox(width: 6),
                    Text(
                      currentLang.nativeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 16, color: textColor.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Theme Button
        Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: const Key('app_top_bar_theme_button'),
            onTap: () => _showThemeSheet(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(themeIcon, size: 18, color: theme.colorScheme.secondary),
                  if (showLabels) ...[
                    const SizedBox(width: 6),
                    Text(
                      currentTheme == AppThemeOption.light
                          ? (AppLocalizations.of(context)?.themeLight ?? 'Light')
                          : currentTheme == AppThemeOption.dark
                              ? (AppLocalizations.of(context)?.themeDark ?? 'Dark')
                              : (AppLocalizations.of(context)?.themeSystem ?? 'Auto'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 16, color: textColor.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
