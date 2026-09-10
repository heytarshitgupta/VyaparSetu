import re

filepath = r'f:\Utthaan\lib\buyer_section\home\buyer_main_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    (r"_buildNavItem\(0, Icons\.grid_view_outlined, Icons\.grid_view, 'Discover'\)", r"_buildNavItem(0, Icons.grid_view_outlined, Icons.grid_view, l10n?.navDiscover ?? 'Discover')"),
    (r"_buildNavItem\(1, Icons\.search_outlined, Icons\.search, 'Search'\)", r"_buildNavItem(1, Icons.search_outlined, Icons.search, l10n?.navSearch ?? 'Search')"),
    (r"_buildNavItem\(2, Icons\.receipt_long_outlined, Icons\.receipt_long, 'Orders'\)", r"_buildNavItem(2, Icons.receipt_long_outlined, Icons.receipt_long, l10n?.navOrders ?? 'Orders')"),
    (r"_buildNavItem\(3, Icons\.person_outline, Icons\.person, 'Account'\)", r"_buildNavItem(3, Icons.person_outline, Icons.person, l10n?.navAccount ?? 'Account')"),
]

for old, new in replacements:
    content = content.replace(old, new)

# We also need to add AppLocalizations if it's not imported, and get l10n in build
if 'AppLocalizations' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../../core/localization/generated/app_localizations.dart';")

if 'final l10n = AppLocalizations.of(context);' not in content:
    content = content.replace('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
