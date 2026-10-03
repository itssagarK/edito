import zipfile
import re

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    for name in ['assets/default_tools_config_v4.json', 'assets/default_tools_config_v5.json']:
        data = z.read(name).decode('utf-8', 'ignore')
        matches = list(re.finditer(r'.{0,40}capcut.{0,40}', data, re.I))
        print(f"=== {name}: {len(matches)} matches ===")
        for m in matches[:5]:
            print("  ", m.group(0))
