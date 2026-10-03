import struct
import re

with open('EditorCopy/resources.arsc', 'rb') as f:
    orig_data = f.read()

sp_pos = 12
string_count = struct.unpack('<I', orig_data[sp_pos+8:sp_pos+12])[0]
strings_start = struct.unpack('<I', orig_data[sp_pos+20:sp_pos+24])[0]
offsets = [struct.unpack('<I', orig_data[sp_pos+28+i*4:sp_pos+32+i*4])[0] for i in range(string_count)]
pool_data_start = sp_pos + strings_start

total_matched = 0
filepath_count = 0
replaced_count = 0

for i in range(string_count):
    off = offsets[i]
    pos = pool_data_start + off
    u16 = orig_data[pos]
    if u16 & 0x80:
        pos += 2
    else:
        pos += 1
    u8 = orig_data[pos]
    if u8 & 0x80:
        pos += 2
    else:
        pos += 1
    raw = orig_data[pos:pos+u8]
    try:
        s = raw.decode('utf-8')
        if 'capcut' in s.lower():
            total_matched += 1
            if s.startswith('res/') or s.startswith('assets/') or s.startswith('lib/'):
                filepath_count += 1
            else:
                replaced_count += 1
                if replaced_count <= 10:
                    print(f"Sample UI string [{i}]: {s[:80]}")
    except:
        pass

print(f"Total capcut in ARSC: {total_matched}")
print(f"File paths: {filepath_count}")
print(f"UI / Text strings: {replaced_count}")
