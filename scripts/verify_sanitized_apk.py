import zipfile
import re
import struct

print("=== VERIFYING SANITIZED edito-premium.apk ===")

with zipfile.ZipFile('edito-premium.apk', 'r') as z:
    # 1. Check ARSC UI strings
    data = z.read('resources.arsc')
    sp_pos = 12
    string_count = struct.unpack('<I', data[sp_pos+8:sp_pos+12])[0]
    strings_start = struct.unpack('<I', data[sp_pos+20:sp_pos+24])[0]
    offsets = [struct.unpack('<I', data[sp_pos+28+i*4:sp_pos+32+i*4])[0] for i in range(string_count)]
    pool_data_start = sp_pos + strings_start

    arsc_cap_count = 0
    for i in range(string_count):
        off = offsets[i]
        pos = pool_data_start + off
        u16 = data[pos]
        pos += 2 if (u16 & 0x80) else 1
        u8 = data[pos]
        pos += 2 if (u8 & 0x80) else 1
        raw = data[pos:pos+u8]
        try:
            s = raw.decode('utf-8')
            if 'capcut' in s.lower():
                arsc_cap_count += 1
        except:
            pass
    print(f"1. ARSC Strings matching 'capcut': {arsc_cap_count}")

    # 2. Check CVR files
    cvr_cap_count = 0
    for name in z.namelist():
        if name.endswith('.cvr'):
            cvr_data = z.read(name)
            if b'CapCut' in cvr_data:
                cvr_cap_count += 1
    print(f"2. CVR files with 'CapCut': {cvr_cap_count}")

    # 3. Check JSON locales in assets
    json_cap_count = 0
    for name in z.namelist():
        if name.startswith('assets/') and name.endswith('.json') and not name.startswith('assets/zoin/'):
            text = z.read(name).decode('utf-8', 'ignore')
            if 'capcut' in text.lower():
                json_cap_count += 1
    print(f"3. Non-zoin JSON assets matching 'capcut': {json_cap_count}")

    # 4. Check XML layout files
    xml_cap_count = 0
    for name in z.namelist():
        if name.endswith('.xml') and name != 'AndroidManifest.xml':
            data = z.read(name)
            if b'CapCut Sans Text' in data:
                xml_cap_count += 1
    print(f"4. XML files with 'CapCut Sans Text': {xml_cap_count}")

print("=== VERIFICATION COMPLETE ===")
