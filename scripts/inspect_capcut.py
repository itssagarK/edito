import zipfile
import struct
import re

with zipfile.ZipFile('edito-premium.apk', 'r') as z:
    data = z.read('resources.arsc')
    sp_pos = 12
    string_count = struct.unpack('<I', data[sp_pos+8:sp_pos+12])[0]
    strings_start = struct.unpack('<I', data[sp_pos+20:sp_pos+24])[0]
    offsets = [struct.unpack('<I', data[sp_pos+28+i*4:sp_pos+32+i*4])[0] for i in range(string_count)]
    pool_data_start = sp_pos + strings_start

    print(f"Total strings: {string_count}")
    matches = []
    for i in range(string_count):
        pos = pool_data_start + offsets[i]
        # parse u16 len
        u16 = data[pos]
        if u16 & 0x80:
            u16_len = ((u16 & 0x7f) << 8) | data[pos+1]
            pos += 2
        else:
            u16_len = u16
            pos += 1
        # parse u8 len
        u8 = data[pos]
        if u8 & 0x80:
            u8_len = ((u8 & 0x7f) << 8) | data[pos+1]
            pos += 2
        else:
            u8_len = u8
            pos += 1
        raw = data[pos:pos+u8_len]
        try:
            s = raw.decode('utf-8')
            if 'capcut' in s.lower():
                matches.append((i, s))
        except:
            pass

    print(f"Found {len(matches)} matches:")
    for idx, s in matches[:40]:
        print(f"[{idx}] {s}")
