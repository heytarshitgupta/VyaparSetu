// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_service.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/theme_provider.dart';

/// Compact quick-action popup menu for phone/tablet AppBar and desktop sidebar footer.
class ProducerQuickActionMenu extends StatelessWidget {
  final VoidCallback? onNavigateToProfile;
  final Future<void> Function()? onSignOut;
  final Widget? customTrigger;

  const ProducerQuickActionMenu({
    super.key,
    this.onNavigateToProfile,
    this.onSignOut,
    this.customTrigger,
  });

  /// Displays the quick actions modal sheet / dialog responsively.
  static void show(
    BuildContext context, {
    VoidCallback? onNavigateToProfile,
    Future<void> Function()? onSignOut,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isNarrow = MediaQuery.sizeOf(context).width < 640;

    if (isNarrow) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => _QuickActionsContent(
          parentContext: context,
          onNavigateToProfile: () {
            Navigator.of(sheetContext).pop();
            onNavigateToProfile?.call();
          },
          onSignOut: () {
            Navigator.of(sheetContext).pop();
            showSignOutConfirmation(context, onSignOut: onSignOut);
          },
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _QuickActionsContent(
              parentContext: context,
              onNavigateToProfile: () {
                Navigator.of(dialogContext).pop();
                onNavigateToProfile?.call();
              },
              onSignOut: () {
                Navigator.of(dialogContext).pop();
                showSignOutConfirmation(context, onSignOut: onSignOut);
              },
            ),
          ),
        ),
      );
    }
  }

  /// Displays the mandatory sign-out confirmation dialog.
  static void showSignOutConfirmation(
    BuildContext context, {
    Future<void> Function()? onSignOut,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmMessage),
        actions: [
          TextButton(
            key: const ValueKey('sign_out_cancel_button'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('sign_out_confirm_button'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                if (onSignOut != null) {
                  await onSignOut();
                } else {
                  await AuthService.instance.signOut();
                }
              } catch (_) {
                // Safe failure fallback
              }
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.initialRoute,
                (route) => false,
              );
            },
            child: Text(l10n.signOutAction),
          ),
        ],
      ),
    );
  }

  /// Shows the quick language selection dialog.
  static void showLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    LanguageProvider? langProvider;
    try {
      langProvider = Provider.of<LanguageProvider>(context, listen: false);
    } catch (_) {}
    final currentLang = langProvider?.appLanguage ?? AppLanguage.english;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Row(
          children: [
            const Icon(Icons.language, size: 22),
            const SizedBox(width: 8),
            Text(l10n.language),
          ],
        ),
        children: [
          RadioListTile<AppLanguage>(
            key: const ValueKey('lang_option_en'),
            title: const Text('English'),
            value: AppLanguage.english,
            groupValue: currentLang,
            onChanged: (val) {
              if (val != null) {
                langProvider?.setAppLanguage(val);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
          RadioListTile<AppLanguage>(
            key: const ValueKey('lang_option_hi'),
            title: const Text('हिन्दी (Hindi)'),
            value: AppLanguage.hindi,
            groupValue: currentLang,
            onChanged: (val) {
              if (val != null) {
                langProvider?.setAppLanguage(val);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
          RadioListTile<AppLanguage>(
            key: const ValueKey('lang_option_pa'),
            title: const Text('ਪੰਜਾਬੀ (Punjabi)'),
            value: AppLanguage.punjabi,
            groupValue: currentLang,
            onChanged: (val) {
              if (val != null) {
                langProvider?.setAppLanguage(val);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  /// Shows the quick appearance / theme selection dialog.
  static void showAppearanceSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    } catch (_) {}
    final currentOption = themeProvider?.themeOption ?? AppThemeOption.system;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Row(
          children: [
            const Icon(Icons.palette_outlined, size: 22),
            const SizedBox(width: 8),
            Text(l10n.appearance),
          ],
        ),
        children: [
          RadioListTile<AppThemeOption>(
            key: const ValueKey('theme_option_system'),
            title: Text(l10n.themeSystem),
            secondary: const Icon(Icons.brightness_auto),
            value: AppThemeOption.system,
            groupValue: currentOption,
            onChanged: (val) {
              if (val != null) {
                themeProvider?.setThemeOption(val);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
          RadioListTile<AppThemeOption>(
            key: const ValueKey('theme_option_light'),
            title: Text(l10n.themeLight),
            secondary: const Icon(Icons.light_mode),
            value: AppThemeOption.light,
            groupValue: currentOption,
            onChanged: (val) {
              if (val != null) {
                themeProvider?.setThemeOption(val);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
          RadioListTile<AppThemeOption>(
            key: const ValueKey('theme_option_dark'),
            title: Text(l10n.themeDark),
            secondary: const Icon(Icons.dark_mode),
            value: AppThemeOption.dark,
            groupValue: currentOption,
            onChanged: (val) {
              if (val != null) {
                themeProvider?.setThemeOption(val);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (customTrigger != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => show(
          context,
          onNavigateToProfile: onNavigateToProfile,
          onSignOut: onSignOut,
        ),
        child: customTrigger,
      );
    }

    return IconButton(
      key: const ValueKey('producer_quick_menu_button'),
      icon: const Icon(Icons.more_vert),
      tooltip: l10n.quickMenuTitle,
      onPressed: () => show(
        context,
        onNavigateToProfile: onNavigateToProfile,
        onSignOut: onSignOut,
      ),
    );
  }
}

class _QuickActionsContent extends StatelessWidget {
  final BuildContext parentContext;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onSignOut;

  const _QuickActionsContent({
    required this.parentContext,
    required this.onNavigateToProfile,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              l10n.quickMenuTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(),

          // 1. My Profile
          ListTile(
            key: const ValueKey('quick_menu_profile'),
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.myProfile),
            onTap: onNavigateToProfile,
          ),

          // 2. Language
          ListTile(
            key: const ValueKey('quick_menu_language'),
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: Builder(
              builder: (ctx) {
                LanguageProvider? langProv;
                try {
                  langProv = Provider.of<LanguageProvider>(ctx);
                } catch (_) {}
                final label = langProv?.appLanguage.nativeLabel ?? 'English';
                return Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.of(context).pop();
              ProducerQuickActionMenu.showLanguageSelector(parentContext);
            },
          ),

          // 3. Appearance
          ListTile(
            key: const ValueKey('quick_menu_appearance'),
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.appearance),
            trailing: Builder(
              builder: (ctx) {
                ThemeProvider? themeProv;
                try {
                  themeProv = Provider.of<ThemeProvider>(ctx);
                } catch (_) {}
                final opt = themeProv?.themeOption ?? AppThemeOption.system;
                final text = opt == AppThemeOption.system
                    ? l10n.themeSystem
                    : opt == AppThemeOption.light
                        ? l10n.themeLight
                        : l10n.themeDark;
                return Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.of(context).pop();
              ProducerQuickActionMenu.showAppearanceSelector(parentContext);
            },
          ),

          // 4. Help & About
          ListTile(
            key: const ValueKey('quick_menu_help'),
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.helpAndAbout),
            onTap: () {
              Navigator.of(context).pop();
              showAboutDialogModal(parentContext);
            },
          ),

          const Divider(),

          // 5. Sign Out
          ListTile(
            key: const ValueKey('quick_menu_sign_out'),
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text(
              l10n.signOutAction,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }

  static void showAboutDialogModal(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, size: 22),
            const SizedBox(width: 8),
            Text(l10n.aboutVyaparSetu),
          ],
        ),
        content: Text(l10n.aboutVyaparSetuContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
