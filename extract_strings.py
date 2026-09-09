import os
import re
import json

def extract_hardcoded_strings(start_dir):
    strings = set()
    
    # Patterns to look for user-facing strings
    # Matches Text('...') or Text("...")
    text_pattern = re.compile(r"Text\(\s*['\"]([^'\"]+[A-Za-z]+[^'\"]*)['\"]")
    # Matches label: '...'
    label_pattern = re.compile(r"(?:label|hintText|tooltip|title|content)\s*:\s*(?:const\s+)?Text\(\s*['\"]([^'\"]+[A-Za-z]+[^'\"]*)['\"]")
    label_direct_pattern = re.compile(r"(?:label|hintText|tooltip|title)\s*:\s*['\"]([^'\"]+[A-Za-z]+[^'\"]*)['\"]")

    for root, dirs, files in os.walk(start_dir):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    for match in text_pattern.findall(content):
                        if not match.startswith('$') and len(match) > 1:
                            strings.add(match.strip())
                    
                    for match in label_pattern.findall(content):
                        if not match.startswith('$') and len(match) > 1:
                            strings.add(match.strip())

                    for match in label_direct_pattern.findall(content):
                        if not match.startswith('$') and len(match) > 1:
                            strings.add(match.strip())

    return list(strings)

buyer_dir = r"f:\Utthaan\lib\buyer_section"
extracted = extract_hardcoded_strings(buyer_dir)

# Filter out obvious non-user-facing strings (like paths or completely lowercase short words)
filtered = []
for s in extracted:
    if len(s) > 2 and re.search(r'[A-Za-z]', s):
        filtered.append(s)

filtered.sort()

output_dict = {
    re.sub(r'[^a-zA-Z0-9]', '', s)[:20].lower() + str(hash(s) % 1000): s for s in filtered
}

with open(r'f:\Utthaan\missing_translations.json', 'w', encoding='utf-8') as f:
    json.dump(output_dict, f, indent=2, ensure_ascii=False)

print(f"Extracted {len(output_dict)} strings to missing_translations.json")
