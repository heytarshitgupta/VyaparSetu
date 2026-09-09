import re

router_path = r'f:\Utthaan\lib\core\routes\app_router.dart'

with open(router_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace return MaterialPageRoute(builder: with return MaterialPageRoute(settings: settings, builder:
# But we need to make sure we don't double replace.
new_content = re.sub(r'MaterialPageRoute\(\s*builder:', r'MaterialPageRoute(settings: settings, builder:', content)

with open(router_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Added settings to MaterialPageRoute calls.")
