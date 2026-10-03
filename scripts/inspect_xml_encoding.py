import zipfile

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    data = z.read('res/_/knh.xml')
    if b'CapCut Sans Text' in data:
        idx = data.find(b'CapCut Sans Text')
        print(f"Found ASCII/UTF-8 at {idx}: {data[idx-4:idx+20]}")
    u16 = 'CapCut Sans Text'.encode('utf-16le')
    if u16 in data:
        idx = data.find(u16)
        print(f"Found UTF-16LE at {idx}: {data[idx-4:idx+36]}")
