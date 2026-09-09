import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';

class BuyerColors {
  final BuildContext _context;
  final bool _listen;
  BuyerColors._(this._context, this._listen);

  static BuyerColors of(BuildContext context, {bool listen = true}) => BuyerColors._(context, listen);

  bool get _isDark {
    try {
      final themeProvider = Provider.of<ThemeProvider>(_context, listen: _listen);
      return themeProvider.isDarkMode(_context);
    } catch (_) {
      // Fallback if ThemeProvider is not available (e.g. testing)
      try {
        return Theme.of(_context).brightness == Brightness.dark;
      } catch (_) {
        return false;
      }
    }
  }

  // Primary brand color (Navy Blue from Vyapar Setu logo)
  Color get primary => _isDark ? const Color(0xFF90CAF9) : const Color(0xFF0A2B5E);
  Color get primaryLight => _isDark ? const Color(0xFFB3E5FC) : const Color(0xFF1E488A);
  Color get primaryDark => _isDark ? const Color(0xFF42A5F5) : const Color(0xFF04193D);
  Color get highlightAccent => _isDark ? const Color(0xFF64B5F6) : const Color(0xFF2874F0);

  // Vibrant Orange Accent
  Color get orangeAccent => _isDark ? const Color(0xFFFFB74D) : const Color(0xFFF49F1C);

  // Backgrounds
  Color get background => _isDark ? const Color(0xFF121212) : const Color(0xFFF1F3F6);
  Color get surface => _isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  Color get cardSurface => _isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF);

  // Accents & Badges
  Color get badgeGreen => _isDark ? const Color(0xFF81C784) : const Color(0xFF2B8A3E);
  Color get badgeGreenLight => _isDark ? const Color(0xFF2E7D32).withOpacity(0.2) : const Color(0xFFE8F5E9);
  Color get badgePink => _isDark ? const Color(0xFFC62828).withOpacity(0.2) : const Color(0xFFFFEBEE);
  Color get badgePinkText => _isDark ? const Color(0xFFEF9A9A) : const Color(0xFFD32F2F);

  // Text
  Color get textPrimary => _isDark ? const Color(0xFFF5F5F5) : const Color(0xFF212121);
  Color get textSecondary => _isDark ? const Color(0xFFB0B0B0) : const Color(0xFF878787);
  Color get textLight => _isDark ? const Color(0xFF757575) : const Color(0xFFC2C2C2);

  // System & Borders
  Color get border => _isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0);
  Color get borderLight => _isDark ? const Color(0xFF333333) : const Color(0xFFF0F0F0);
  Color get divider => _isDark ? const Color(0xFF333333) : const Color(0xFFF0F0F0);
}
