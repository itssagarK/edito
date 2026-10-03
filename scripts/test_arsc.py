import struct
import re

with open('EditorCopy/resources.arsc', 'rb') as f:
    orig_data = f.read()

sp_pos = 12
sp_type, sp_header_size, orig_sp_size = struct.unpack('<HHI', orig_data[sp_pos:sp_pos+8])
string_count, style_count, flags, strings_start, styles_start = struct.unpack('<IIIII', orig_data[sp_pos+8:sp_pos+28])
offsets = [struct.unpack('<I', orig_data[sp_pos+28+i*4:sp_pos+32+i*4])[0] for i in range(string_count)]
pool_data_start = sp_pos + strings_start

print(f"Total string count in ARSC: {string_count}")

# Check matching strings
capcut_pattern = re.compile(r'(?i)capcut')
bytedance_pattern = re.compile(r'(?i)bytedance')

matches = 0
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
        if capcut_pattern.search(s) or bytedance_pattern.search(s):
            matches += 1
    except:
        pass

print(f"Found {matches} strings with capcut or bytedance in raw ARSC.")
