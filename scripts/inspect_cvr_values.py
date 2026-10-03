import zipfile
import base64

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    for name in z.namelist():
        if name.endswith('.cvr'):
            lines = z.read(name).decode('utf-8', 'ignore').splitlines()
            for line in lines:
                parts = line.split('|')
                if len(parts) >= 3:
                    val_b64 = parts[2]
                    try:
                        val = base64.b64decode(val_b64).decode('utf-8', 'ignore')
                        if 'capcut' in val.lower():
                            print(f"[{name}] {parts[1]} -> {val}")
                    except:
                        pass
