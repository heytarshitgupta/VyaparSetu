import os
import re

directory = r'f:\Utthaan\lib\buyer_section'

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Find all const widgets that contain BuyerColors and remove const
            # A simple heuristic: remove 'const ' from any line containing 'BuyerColors'
            lines = content.split('\n')
            for i in range(len(lines)):
                if 'BuyerColors' in lines[i]:
                    lines[i] = lines[i].replace('const ', '')
            
            content = '\n'.join(lines)
            
            # Replace BuyerColors. with BuyerColors.of(context).
            # But avoid replacing BuyerColors.of(context). if it's already there
            content = re.sub(r'BuyerColors\.(?!of\()', 'BuyerColors.of(context).', content)
            
            if content != original_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f'Updated {filepath}')
