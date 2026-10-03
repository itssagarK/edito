import zipfile
import re

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    for name in [
        'assets/offline/image_lynx_subscription_open_screen/template.js',
        'assets/offline/image_lynx_subscription_modal/pages/vip_upgrade_modal/template.js'
    ]:
        data = z.read(name)
        matches = list(re.finditer(rb'["\'`][^"\'`]*CapCut[^"\'`]*["\'`]', data))
        print(f"=== {name}: {len(matches)} string literals with CapCut ===")
        for m in matches[:10]:
            print("  ", m.group(0)[:100])
