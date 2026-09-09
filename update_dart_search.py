import re

files_search = r'f:\Utthaan\lib\buyer_section\marketplace\marketplace_search_screen.dart'
files_requests = r'f:\Utthaan\lib\buyer_section\my_requests\buyer_requests_screen.dart'

with open(files_search, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'Search products...'", "l10n?.searchProducts ?? 'Search products...'")
content = content.replace("'All Categories'", "l10n?.allCategories ?? 'All Categories'")
content = content.replace("'My Cart'", "l10n?.myCart ?? 'My Cart'")
content = content.replace("'No Products'", "l10n?.noProducts ?? 'No Products'")
content = content.replace("'No products available in this category yet.'", "l10n?.noProductsCategory ?? 'No products available in this category yet.'")

# Also need to dynamically translate category names in the ListView
# find: Text(category,
# replace: Text(category == 'For You' ? (l10n?.forYou ?? 'For You') : category == 'Textiles' ? (l10n?.textiles ?? 'Textiles') : category == 'Spices' ? (l10n?.spices ?? 'Spices') : category == 'Handicrafts' ? (l10n?.handicrafts ?? 'Handicrafts') : category == 'Food' ? (l10n?.food ?? 'Food') : category,
content = content.replace("Text(\n                          category,", "Text(\n                          category == 'For You' ? (l10n?.forYou ?? 'For You') : category == 'Textiles' ? (l10n?.textiles ?? 'Textiles') : category == 'Spices' ? (l10n?.spices ?? 'Spices') : category == 'Handicrafts' ? (l10n?.handicrafts ?? 'Handicrafts') : category == 'Food' ? (l10n?.food ?? 'Food') : category,")


if 'AppLocalizations' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../../core/localization/generated/app_localizations.dart';")
if 'final l10n = AppLocalizations.of(context);' not in content:
    content = content.replace('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);')

with open(files_search, 'w', encoding='utf-8') as f:
    f.write(content)

with open(files_requests, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'My Requirements'", "l10n?.myRequirements ?? 'My Requirements'")
content = content.replace("'No requests yet'", "l10n?.noRequests ?? 'No requests yet'")
content = content.replace("'Post a custom requirement to start receiving quotes from verified producers.'", "l10n?.noRequestsSub ?? 'Post a custom requirement to start receiving quotes from verified producers.'")
content = content.replace("'\${req['responses']} Responses'", "'${req['responses']} ${l10n?.responsesText ?? 'Responses'}'")
content = content.replace("req['status'].toString().toUpperCase()", "req['status'].toString().replaceAll('Receiving Quotes', l10n?.receivingQuotes ?? 'Receiving Quotes').replaceAll('Closed', l10n?.closed ?? 'Closed').toUpperCase()")

if 'AppLocalizations' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../../core/localization/generated/app_localizations.dart';")
if 'final l10n = AppLocalizations.of(context);' not in content:
    content = content.replace('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);')

with open(files_requests, 'w', encoding='utf-8') as f:
    f.write(content)
