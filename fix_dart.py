import re

filepath = r'f:\Utthaan\lib\buyer_section\home\tabs\buyer_home_tab.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix missing l10n in _showFilterSheet
if 'final l10n = AppLocalizations.of(context);' not in content.split('void _showFilterSheet(BuildContext context) {')[1].split('showModalBottomSheet(')[0]:
    content = content.replace('void _showFilterSheet(BuildContext context) {\n    showModalBottomSheet(', 'void _showFilterSheet(BuildContext context) {\n    final l10n = AppLocalizations.of(context);\n    showModalBottomSheet(')

# Remove invalid consts
content = content.replace("const Text(l10n?.filterByCategory", "Text(l10n?.filterByCategory")
content = content.replace("const Text(l10n?.close", "Text(l10n?.close")
content = content.replace("const Center(child: Text(l10n?.noProductsFound", "Center(child: Text(l10n?.noProductsFound")
content = content.replace("const Text(l10n?.noProductsFound", "Text(l10n?.noProductsFound")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

# Fix product_card missing l10n
filepath_card = r'f:\Utthaan\lib\buyer_section\home\widgets\product_card.dart'
with open(filepath_card, 'r', encoding='utf-8') as f:
    content_card = f.read()

if 'final l10n = AppLocalizations.of(context);' not in content_card:
    content_card = content_card.replace('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);')

with open(filepath_card, 'w', encoding='utf-8') as f:
    f.write(content_card)
