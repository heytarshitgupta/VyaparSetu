import os

lib_path = r'f:\Utthaan\lib'

for root, _, files in os.walk(lib_path):
    for file in files:
        if file.endswith('.dart'):
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content.replace('features/buyer', 'buyer_section')
            new_content = new_content.replace('features/shared', 'buyer_section/screens/shared')
            
            if new_content != content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {file_path}")
