import zipfile
import base64
import re

cvr_path = 'composeResources/com.lemon.clipmonetize.compliancemp_ui.generated.resources/values/strings.commonMain.cvr'

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    raw_content = z.read(cvr_path).decode('utf-8')

new_lines = []
modified = 0
for line in raw_content.splitlines():
    parts = line.split('|')
    if len(parts) >= 3:
        try:
            val = base64.b64decode(parts[2]).decode('utf-8')
            orig_val = val
            val = re.sub(r'(?i)CapCut Pro', 'Edito Premium', val)
            val = re.sub(r'(?i)CapCut Standard', 'Edito Standard', val)
            val = re.sub(r'CAPCUT', 'EDITO PREMIUM', val)
            val = re.sub(r'CapCut', 'Edito Premium', val)
            val = re.sub(r'Capcut', 'Edito Premium', val)
            val = re.sub(r'capcut\.com', 'edito.app', val)
            val = re.sub(r'capcut', 'edito', val)
            val = re.sub(r'ByteDance', 'Edito Team', val)
            val = re.sub(r'bytedance', 'edito', val)
            if val != orig_val:
                modified += 1
                parts[2] = base64.b64encode(val.encode('utf-8')).decode('ascii')
                print(f"Patched: {orig_val[:40]} -> {val[:40]}")
        except Exception as e:
            pass
    new_lines.append('|'.join(parts))

new_content = '\n'.join(new_lines) + '\n'
print(f"Successfully patched {modified} strings in {cvr_path}!")
