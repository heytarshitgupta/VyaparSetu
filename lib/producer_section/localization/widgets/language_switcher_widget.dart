import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable language selector widget for Producer screens.
/// Displays clear options: English, हिन्दी, ਪੰਜਾਬੀ.
class LanguageSwitcherWidget extends StatelessWidget {
  final bool isCompact;

  const LanguageSwitcherWidget({
    super.key,
    this.isCompact = false,
  });

  void _showLanguageSelectionSheet(BuildContext context) {
    LanguageProvider? languageProvider;
    try {
      languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    } catch (_) {
      // Graceful fallback
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surface,
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.language, size: 22, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Choose Language / भाषा चुनें / ਭਾਸ਼ਾ ਚੁਣੋ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          key: Key('language_option_${lang.locale.languageCode}'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            lang.nativeLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            lang.englishLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
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

  @override
  Widget build(BuildContext context) {
    LanguageProvider? languageProvider;
    try {
      languageProvider = Provider.of<LanguageProvider>(context);
    } catch (_) {
      // Fallback for isolated widget tests without LanguageProvider
    }
    final currentLang = languageProvider?.appLanguage ?? AppLanguage.english;

    if (isCompact) {
      return InkWell(
        key: const Key('language_switcher_compact_button'),
        onTap: () => _showLanguageSelectionSheet(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                currentLang.nativeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      key: const Key('language_switcher_button'),
      onPressed: () => _showLanguageSelectionSheet(context),
      icon: const Icon(Icons.language, size: 18),
      label: Text(
        currentLang.nativeLabel,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
