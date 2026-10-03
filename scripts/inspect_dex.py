import zipfile
import re

with zipfile.ZipFile('edito-premium.apk', 'r') as z:
    for dex_name in ['classes.dex', 'classes14.dex', 'classes25.dex']:
        data = z.read(dex_name)
        matches = list(re.finditer(rb'[ -~]{3,30}capcut[ -~]{0,30}', data, re.I))
        print(f"=== {dex_name} ({len(matches)} matches) ===")
        # Print sample of unique matches
        samples = set(m.group(0).decode('latin1', 'ignore') for m in matches)
        for s in list(samples)[:25]:
            print("  ", s)
