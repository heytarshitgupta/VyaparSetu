import os

def replace_in_file(file_path, replacements):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    for old, new in replacements:
        content = content.replace(old, new)
        
    if content != original:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {file_path}")

replace_in_file(r"f:\Utthaan\lib\buyer_section\screens\shared\placeholder_screen.dart", [
    ("../../core/", "../../../core/")
])

replace_in_file(r"f:\Utthaan\lib\buyer_section\screens\shared\auth_screen.dart", [
    ("../../core/", "../../../core/"),
    ("../../buyer_section/onboarding/", "../../onboarding/")
])

replace_in_file(r"f:\Utthaan\lib\buyer_section\screens\shared\otp_screen.dart", [
    ("../../core/", "../../../core/"),
    ("../../buyer_section/onboarding/", "../../onboarding/")
])

replace_in_file(r"f:\Utthaan\lib\buyer_section\home\buyer_main_screen.dart", [
    ("../../shared/", "../screens/shared/")
])

replace_in_file(r"f:\Utthaan\lib\buyer_section\home\tabs\buyer_home_tab.dart", [
    ("../../../buyer/onboarding/", "../../onboarding/")
])
