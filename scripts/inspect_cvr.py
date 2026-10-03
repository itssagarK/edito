import zipfile

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    for name in z.namelist():
        if name.endswith('.cvr'):
            data = z.read(name)
            if b'CapCut' in data or b'capcut' in data:
                print(f"=== {name} (size {len(data)}) ===")
                print(data[:200])
                idx = data.lower().find(b'capcut')
                print("Context:", data[max(0, idx-40):min(len(data), idx+60)])
                break
