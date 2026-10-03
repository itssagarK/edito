import zipfile
import re

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    for item in z.infolist():
        if item.filename.startswith('assets/'):
            data = z.read(item.filename)
            if b'capcut' in data.lower():
                print(f"[{item.filename}] size: {len(data)}, type: {item.filename.split('.')[-1]}")
