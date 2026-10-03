import zipfile
import re
import os

def scan_zip():
    print("=== Scanning capEditor.zip for CapCut references ===")
    capcut_pattern = re.compile(b'(?i)capcut')
    
    with zipfile.ZipFile('capEditor.zip', 'r') as z:
        for info in z.infolist():
            name = info.filename
            if name.endswith(('.so', '.ttf', '.png', '.jpg', '.webp', '.mp3', '.wav', '.bin')):
                continue
            try:
                data = z.read(name)
                matches = capcut_pattern.findall(data)
                if matches:
                    print(f"[{name}] {len(matches)} occurrences of 'capcut'")
            except Exception as e:
                pass

if __name__ == '__main__':
    scan_zip()
