import re

filepath = r'f:\Utthaan\lib\buyer_section\profile\buyer_profile_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replacements
replacements = [
    (r"'Quick Links'", r"l10n?.quickLinks ?? 'Quick Links'"),
    (r"'My Orders'", r"l10n?.myOrders ?? 'My Orders'"),
    (r"'Wishlist'", r"l10n?.wishlist ?? 'Wishlist'"),
    (r"'My Requirements'", r"l10n?.myRequirements ?? 'My Requirements'"),
    (r"'Business Information'", r"l10n?.businessInformation ?? 'Business Information'"),
    (r"'Business Name'", r"l10n?.businessName ?? 'Business Name'"),
    (r"'Category'", r"l10n?.category ?? 'Category'"),
    (r"'Email'", r"l10n?.email ?? 'Email'"),
    (r"'Phone'", r"l10n?.phone ?? 'Phone'"),
    (r"'Address'", r"l10n?.address ?? 'Address'"),
    (r"'Recent Activity'", r"l10n?.recentActivity ?? 'Recent Activity'"),
    (r"'Dark Mode'", r"l10n?.darkMode ?? 'Dark Mode'"),
    (r"'Notifications'", r"l10n?.notifications ?? 'Notifications'"),
    (r"'Logout'", r"l10n?.logout ?? 'Logout'"),
    (r"'Not provided'", r"l10n?.notProvided ?? 'Not provided'"),
]

for old, new in replacements:
    content = content.replace(old, new)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
