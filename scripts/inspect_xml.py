import zipfile
import re

with zipfile.ZipFile('edito-premium.apk', 'r') as z:
    for name in z.namelist():
        if name.endswith('.xml') and 'capcut' in z.read(name).decode('latin1', 'ignore').lower():
            data = z.read(name)
            # Find occurrences of capcut
            matches = list(re.finditer(rb'(?i)capcut', data))
            print(f"[{name}] {len(matches)} matches")
            for m in matches[:3]:
                start = max(0, m.start() - 30)
                end = min(len(data), m.end() + 30)
                print(f"   ... {data[start:end]} ...")
