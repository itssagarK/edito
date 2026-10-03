import zipfile
import re

json_files = []
with zipfile.ZipFile('capEditor.zip', 'r') as z:
    for name in z.namelist():
        if name.startswith('assets/') and name.endswith('.json'):
            data = z.read(name)
            if b'capcut' in data.lower():
                json_files.append(name)

print(f"Total json asset files containing capcut: {len(json_files)}")

# Test replacing in a few key files
sample = json_files[0]
with zipfile.ZipFile('capEditor.zip', 'r') as z:
    content = z.read(sample).decode('utf-8', 'ignore')

print(f"Sample file: {sample}")
matches_before = len(re.findall(r'(?i)capcut', content))
print(f"Matches before: {matches_before}")

# Apply replacements
replacements = [
    (r'(?i)CapCut Pro', 'Edito Premium'),
    (r'(?i)CapCut Standard', 'Edito Standard'),
    (r'CAPCUT', 'EDITO PREMIUM'),
    (r'CapCut', 'Edito Premium'),
    (r'Capcut', 'Edito Premium'),
    (r'https?://(?:www\.)?capcut\.com', 'https://www.edito.app'),
    (r'capcut\.com', 'edito.app'),
    (r'capcut://', 'editop://'),
    (r'capcut', 'edito'),
    (r'ByteDance', 'Edito Team'),
    (r'bytedance', 'edito')
]

for pat, repl in replacements:
    content = re.sub(pat, repl, content)

matches_after = len(re.findall(r'(?i)capcut', content))
print(f"Matches after: {matches_after}")
