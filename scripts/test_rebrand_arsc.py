import struct
import re

with open('EditorCopy/resources.arsc', 'rb') as f:
    orig_data = f.read()

OLD_PKG = "com.lemon.lvoverseas"
NEW_PKG = "com.edito.premiumpak"

t_type, t_header_size, orig_t_size = struct.unpack('<HHI', orig_data[:8])
pkg_count = struct.unpack('<I', orig_data[8:12])[0]

sp_pos = 12
sp_type, sp_header_size, orig_sp_size = struct.unpack('<HHI', orig_data[sp_pos:sp_pos+8])
string_count, style_count, flags, strings_start, styles_start = struct.unpack('<IIIII', orig_data[sp_pos+8:sp_pos+28])
offsets = [struct.unpack('<I', orig_data[sp_pos+28+i*4:sp_pos+32+i*4])[0] for i in range(string_count)]
pool_data_start = sp_pos + strings_start

new_strings = []
replaced_count = 0

for i in range(string_count):
    off = offsets[i]
    pos = pool_data_start + off
    u16_char_len = orig_data[pos]
    if u16_char_len & 0x80:
        u16_char_len = ((u16_char_len & 0x7F) << 8) | orig_data[pos+1]
        pos += 2
    else:
        pos += 1
    u8_byte_len = orig_data[pos]
    if u8_byte_len & 0x80:
        u8_byte_len = ((u8_byte_len & 0x7F) << 8) | orig_data[pos+1]
        pos += 2
    else:
        pos += 1
    raw = orig_data[pos:pos+u8_byte_len]
    try:
        s = raw.decode('utf-8')
        orig_s = s
        
        # Package replacement
        if OLD_PKG in s:
            s = s.replace(OLD_PKG, NEW_PKG)
            
        # Support emails
        s = s.replace('capcut.support@bytedance.com', 'support@edito.app')
        s = s.replace('support@us.capcut.com', 'support@edito.app')
        
        # Explicit primary app_name replacement (Index 33267)
        if i == 33267:
            s = 'Edito Premium'
            
        # If not a resource/file path:
        if not (orig_s.startswith('res/') or orig_s.startswith('assets/') or orig_s.startswith('lib/')):
            # Branding replacements (ordered from most specific to least specific)
            # 1. URLs
            s = s.replace('https://www.capcut.com', 'https://www.edito.app')
            s = s.replace('http://www.capcut.com', 'http://www.edito.app')
            s = s.replace('https://capcut.com', 'https://edito.app')
            s = s.replace('http://capcut.com', 'http://edito.app')
            s = s.replace('www.capcut.com', 'www.edito.app')
            s = s.replace('capcut.com', 'edito.app')
            s = s.replace('capcut.net', 'edito.app')
            s = s.replace('capcut.org', 'edito.app')
            
            # 2. ISI Government remnants
            s = s.replace('Edito - ISI Government', 'Edito Premium')
            s = s.replace('EDITO - ISI GOVERNMENT', 'EDITO PREMIUM')
            s = s.replace('ISI Government', 'Edito Premium')
            s = s.replace('isi government', 'edito premium')
            
            # 3. CapCut Pro / Standard / variations
            s = re.sub(r'(?i)CapCut Pro', 'Edito Premium', s)
            s = re.sub(r'(?i)CapCut Standard', 'Edito Standard', s)
            s = re.sub(r'CAPCUT', 'EDITO PREMIUM', s)
            s = re.sub(r'CapCut', 'Edito Premium', s)
            s = re.sub(r'Capcut', 'Edito Premium', s)
            s = re.sub(r'capcut', 'edito', s)
            
            # 4. ByteDance
            s = re.sub(r'ByteDance', 'Edito Team', s)
            s = re.sub(r'bytedance', 'edito', s)
            
        if s != orig_s:
            raw = s.encode('utf-8')
            replaced_count += 1
    except:
        pass
    new_strings.append(raw)

print(f"Rebranded {replaced_count} UI strings in resources.arsc!")

# Check remaining matches
remaining = 0
for i, raw in enumerate(new_strings):
    try:
        s = raw.decode('utf-8')
        if 'capcut' in s.lower():
            remaining += 1
            if remaining <= 10:
                print(f"Remaining [{i}]: {s}")
    except:
        pass
print(f"Remaining strings with capcut in ARSC: {remaining}")
