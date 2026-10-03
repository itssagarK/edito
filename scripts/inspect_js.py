import zipfile
import re

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    for name in [
        'assets/offline/image_lynx_subscription_open_screen/template.js',
        'assets/offline/image_lynx_subscription_modal/pages/vip_upgrade_modal/template.js'
    ]:
        if name in z.namelist():
            data = z.read(name)
            matches = list(re.finditer(rb'[a-zA-Z0-9_.\-\/]{0,20}capcut[a-zA-Z0-9_.\-\/]{0,20}', data, re.I))
            print(f"=== {name}: {len(matches)} matches ===")
            samples = set(m.group(0).decode('latin1') for m in matches)
            for s in list(samples)[:15]:
                print("  ", s)
