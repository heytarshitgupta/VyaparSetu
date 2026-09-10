import json

files = {
    'en': 'f:/Utthaan/lib/core/localization/l10n/app_en.arb',
    'hi': 'f:/Utthaan/lib/core/localization/l10n/app_hi.arb',
    'pa': 'f:/Utthaan/lib/core/localization/l10n/app_pa.arb'
}

new_strings = {
    'en': {
        'searchProducts': 'Search products...',
        'myCart': 'My Cart',
        'noProducts': 'No Products',
        'noProductsCategory': 'No products available in this category yet.',
        'noRequests': 'No requests yet',
        'noRequestsSub': 'Post a custom requirement to start receiving quotes from verified producers.',
        'responsesText': 'Responses',
        'receivingQuotes': 'Receiving Quotes',
        'closed': 'Closed'
    },
    'hi': {
        'searchProducts': 'उत्पाद खोजें...',
        'myCart': 'मेरी कार्ट',
        'noProducts': 'कोई उत्पाद नहीं',
        'noProductsCategory': 'इस श्रेणी में अभी तक कोई उत्पाद उपलब्ध नहीं है।',
        'noRequests': 'अभी तक कोई अनुरोध नहीं',
        'noRequestsSub': 'सत्यापित उत्पादकों से उद्धरण प्राप्त करना शुरू करने के लिए एक कस्टम आवश्यकता पोस्ट करें।',
        'responsesText': 'प्रतिक्रियाएं',
        'receivingQuotes': 'उद्धरण प्राप्त कर रहे हैं',
        'closed': 'बंद'
    },
    'pa': {
        'searchProducts': 'ਉਤਪਾਦ ਖੋਜੋ...',
        'myCart': 'ਮੇਰੀ ਕਾਰਟ',
        'noProducts': 'ਕੋਈ ਉਤਪਾਦ ਨਹੀਂ',
        'noProductsCategory': 'ਇਸ ਸ਼੍ਰੇਣੀ ਵਿੱਚ ਅਜੇ ਕੋਈ ਉਤਪਾਦ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।',
        'noRequests': 'ਅਜੇ ਕੋਈ ਬੇਨਤੀ ਨਹੀਂ',
        'noRequestsSub': 'ਪ੍ਰਮਾਣਿਤ ਉਤਪਾਦਕਾਂ ਤੋਂ ਹਵਾਲੇ ਪ੍ਰਾਪਤ ਕਰਨਾ ਸ਼ੁਰੂ ਕਰਨ ਲਈ ਇੱਕ ਕਸਟਮ ਲੋੜ ਪੋਸਟ ਕਰੋ।',
        'responsesText': 'ਜਵਾਬ',
        'receivingQuotes': 'ਹਵਾਲੇ ਪ੍ਰਾਪਤ ਕਰ ਰਹੇ ਹਾਂ',
        'closed': 'ਬੰਦ'
    }
}

for lang, filepath in files.items():
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    for k, v in new_strings[lang].items():
        data[k] = v
        if lang == 'en':
            data['@' + k] = {'description': 'Added for search and requests screen'}
            
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
    print(f'Updated {filepath}')
