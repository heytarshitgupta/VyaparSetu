import json
import os

files = {
    'en': 'f:/Utthaan/lib/core/localization/l10n/app_en.arb',
    'hi': 'f:/Utthaan/lib/core/localization/l10n/app_hi.arb',
    'pa': 'f:/Utthaan/lib/core/localization/l10n/app_pa.arb'
}

new_strings = {
    'en': {
        'navDiscover': 'Discover',
        'navSearch': 'Search',
        'navOrders': 'Orders',
        'navAccount': 'Account'
    },
    'hi': {
        'navDiscover': 'खोजें',
        'navSearch': 'सर्च',
        'navOrders': 'ऑर्डर',
        'navAccount': 'खाता'
    },
    'pa': {
        'navDiscover': 'ਖੋਜੋ',
        'navSearch': 'ਸਰਚ',
        'navOrders': 'ਆਰਡਰ',
        'navAccount': 'ਖਾਤਾ'
    }
}

for lang, filepath in files.items():
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Add new strings
    for k, v in new_strings[lang].items():
        data[k] = v
        if lang == 'en':
            data['@' + k] = {'description': 'Bottom navigation bar item'}
            
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
    print(f'Updated {filepath}')
