import zipfile

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    for name in ['assets/zoin/metadata.txt', 'assets/snapboost_preload_cut_same.txt']:
        data = z.read(name).decode('utf-8', 'ignore')
        print(f"=== {name} ===")
        for line in data.splitlines():
            if 'capcut' in line.lower():
                print("  ", line[:100])
