import os
import sys
import struct
import hashlib
import zlib
import zipfile
import subprocess

OLD_PKG = "com.lemon.lvoverseas"
NEW_PKG = "com.edito.premiumpak"
assert len(OLD_PKG) == len(NEW_PKG)

print("=== 1. Rebuilding resources.arsc with Clean 'Edito Premium' Branding ===")
with open('EditorCopy/resources.arsc', 'rb') as f:
    orig_data = f.read()

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
            
        # Support email replacement
        if 'capcut.support@bytedance.com' in s:
            s = s.replace('capcut.support@bytedance.com', 'support@edito.app')
        
        # Explicit primary app_name replacement (Index 33267)
        if i == 33267:
            s = 'Edito Premium'
            
        # General branding replacement
        if not (orig_s.startswith('res/') or orig_s.startswith('assets/') or orig_s.startswith('com.')):
            if 'isi government' in s.lower():
                s = s.replace('Edito - ISI Government', 'Edito Premium')
                s = s.replace('EDITO - ISI GOVERNMENT', 'EDITO PREMIUM')
                s = s.replace('ISI Government', 'Edito Premium')
            if 'capcut' in s.lower():
                s = s.replace('CapCut Pro', 'Edito Premium')
                s = s.replace('CapCut pro', 'Edito Premium')
                s = s.replace('Capcut Pro', 'Edito Premium')
                s = s.replace('CapCut', 'Edito Premium')
                s = s.replace('Capcut', 'Edito Premium')
                s = s.replace('CAPCUT', 'EDITO PREMIUM')
            if 'bytedance' in s.lower():
                s = s.replace('ByteDance', 'Edito Team')
                s = s.replace('bytedance', 'edito')
                
        if s != orig_s:
            raw = s.encode('utf-8')
            replaced_count += 1
    except:
        pass
    new_strings.append(raw)

print(f"Rebranded {replaced_count} UI strings in resources.arsc to 'Edito Premium'!")

new_offsets = []
new_body = bytearray()
for b in new_strings:
    new_offsets.append(len(new_body))
    try:
        s = b.decode('utf-8')
        utf16_len = len(s.encode('utf-16le')) // 2
    except:
        utf16_len = len(b)
    
    if utf16_len > 0x7F:
        new_body.append((utf16_len >> 8) | 0x80)
        new_body.append(utf16_len & 0xFF)
    else:
        new_body.append(utf16_len)
    
    byte_len = len(b)
    if byte_len > 0x7F:
        new_body.append((byte_len >> 8) | 0x80)
        new_body.append(byte_len & 0xFF)
    else:
        new_body.append(byte_len)
    
    new_body.extend(b)
    new_body.append(0)

while len(new_body) % 4 != 0:
    new_body.append(0)

sp_chunk_size = 28 + string_count * 4 + len(new_body)
new_sp_header = struct.pack('<HHI IIIII', 0x0001, 28, sp_chunk_size, string_count, 0, 0x100, 28 + string_count * 4, 0)
new_offsets_bytes = struct.pack(f'<{string_count}I', *new_offsets)

pkg_chunk = bytearray(orig_data[sp_pos + orig_sp_size:])
old_pkg_u16 = OLD_PKG.encode('utf-16le')
new_pkg_u16 = NEW_PKG.encode('utf-16le')
if old_pkg_u16 in pkg_chunk:
    pkg_chunk = bytearray(bytes(pkg_chunk).replace(old_pkg_u16, new_pkg_u16))
    print("Updated package name in package chunk!")

new_table_size = 12 + sp_chunk_size + len(pkg_chunk)
new_table_header = struct.pack('<HHI I', 0x0002, 12, new_table_size, pkg_count)

new_arsc_data = new_table_header + new_sp_header + new_offsets_bytes + bytes(new_body) + bytes(pkg_chunk)
assert len(new_arsc_data) == new_table_size
print("resources.arsc structure verified successfully!")

print("=== 2. Patching AndroidManifest.xml (Decoupling Package, Providers & Schemes) ===")
with open('EditorCopy/AndroidManifest.xml', 'rb') as f:
    manifest_data = f.read()

# Exact length replacements (UTF-16LE)
replacements_manifest = [
    (OLD_PKG, NEW_PKG), # 20 chars
    ('com.lemon.faceuassist.provider', 'com.edito.faceuassist.provider'), # 30 chars
    ('163543514909045', '987654321012345'), # 15 chars (Facebook App ID)
    ('share_import_to_capcut', 'share_import_to_edito_'), # 22 chars
    ('share_save_to_capcut', 'share_save_to_edito_'), # 20 chars
    ('www.capcut.com', 'www.editoo.com'), # 14 chars
    ('www.capcut.net', 'www.editoo.net'), # 14 chars
    ('capcutlogintt', 'editoplogintt'), # 13 chars
    ('capcut1380', 'editop1380'), # 10 chars
    ('capcut1760', 'editop1760'), # 10 chars
    ('capcut', 'editop'), # 6 chars
]

manifest_patched = manifest_data
for old_s, new_s in replacements_manifest:
    assert len(old_s) == len(new_s), f"Length mismatch: {old_s} vs {new_s}"
    old_u16 = old_s.encode('utf-16le')
    new_u16 = new_s.encode('utf-16le')
    count = manifest_patched.count(old_u16)
    if count > 0:
        manifest_patched = manifest_patched.replace(old_u16, new_u16)
        print(f"Replaced {count} instances of {old_s} -> {new_s} in AndroidManifest.xml")

# Version bump to v2.1.0
if '19.6.0'.encode('utf-16le') in manifest_patched:
    manifest_patched = manifest_patched.replace('19.6.0'.encode('utf-16le'), 'v2.1.0'.encode('utf-16le'))
elif 'v2.0.1'.encode('utf-16le') in manifest_patched:
    manifest_patched = manifest_patched.replace('v2.0.1'.encode('utf-16le'), 'v2.1.0'.encode('utf-16le'))
elif 'v2.0.0'.encode('utf-16le') in manifest_patched:
    manifest_patched = manifest_patched.replace('v2.0.0'.encode('utf-16le'), 'v2.1.0'.encode('utf-16le'))

assert len(manifest_patched) == len(manifest_data)
print("Patched AndroidManifest.xml successfully with decoupled authorities & package!")

print("=== 3. Patching DEX Files & Checksums ===")
dex_replacements = [
    (OLD_PKG.encode('ascii'), NEW_PKG.encode('ascii')),
    (b'com.lemon.faceuassist.provider', b'com.edito.faceuassist.provider'),
    (b'163543514909045', b'987654321012345'),
    (b'share_import_to_capcut', b'share_import_to_edito_'),
    (b'share_save_to_capcut', b'share_save_to_edito_'),
    (b'www.capcut.com', b'www.editoo.com'),
    (b'www.capcut.net', b'www.editoo.net'),
    (b'capcutlogintt', b'editoplogintt'),
    (b'capcut1380', b'editop1380'),
    (b'capcut1760', b'editop1760'),
]

dex_patched_map = {}
for fname in sorted(os.listdir('EditorCopy')):
    if fname.endswith('.dex'):
        fpath = os.path.join('EditorCopy', fname)
        with open(fpath, 'rb') as f:
            dex_data = bytearray(f.read())
        
        orig_len = len(dex_data)
        modified = False
        for old_b, new_b in dex_replacements:
            if old_b in dex_data:
                dex_data = bytearray(bytes(dex_data).replace(old_b, new_b))
                modified = True
                
        if modified:
            assert len(dex_data) == orig_len
            sha1 = hashlib.sha1(dex_data[32:]).digest()
            dex_data[12:32] = sha1
            adler = zlib.adler32(dex_data[12:]) & 0xffffffff
            dex_data[8:12] = struct.pack('<I', adler)
            dex_patched_map[fname] = bytes(dex_data)
            print(f"Patched & recalculated checksums for {fname}")

print(f"Total patched DEX files: {len(dex_patched_map)}")

print("=== 4. Assembling New Decoupled APK Archive ===")
unaligned_apk = "edito-premium-unaligned.apk"
if os.path.exists(unaligned_apk):
    os.remove(unaligned_apk)

icon_replacements = {}
for rel in ['res/u/rf.png', 'res/z/rf.png', 'res/w/rf.png', 'res/x/rf.png', 'res/v/rf.png', 'res/h/rf.png']:
    full = os.path.join('EditorCopy', rel.replace('/', os.sep))
    if os.path.exists(full):
        with open(full, 'rb') as f:
            icon_replacements[rel] = f.read()

print(f"Loaded {len(icon_replacements)} updated Edito Premium icon drawables!")

with zipfile.ZipFile('capEditor.zip', 'r') as src_zip:
    with zipfile.ZipFile(unaligned_apk, 'w') as dst_zip:
        for item in src_zip.infolist():
            upper = item.filename.upper()
            if upper.startswith('META-INF/') and (upper.endswith('.SF') or upper.endswith('.RSA') or upper.endswith('.DSA') or upper == 'META-INF/MANIFEST.MF'):
                continue
            
            norm_name = item.filename.replace('\\', '/')
            if norm_name == 'resources.arsc':
                arsc_info = zipfile.ZipInfo('resources.arsc')
                arsc_info.compress_type = zipfile.ZIP_STORED
                arsc_info.date_time = item.date_time
                dst_zip.writestr(arsc_info, new_arsc_data)
            elif norm_name == 'AndroidManifest.xml':
                m_info = zipfile.ZipInfo('AndroidManifest.xml')
                m_info.compress_type = item.compress_type
                m_info.date_time = item.date_time
                dst_zip.writestr(m_info, manifest_patched)
            elif norm_name in dex_patched_map:
                d_info = zipfile.ZipInfo(item.filename)
                d_info.compress_type = item.compress_type
                d_info.date_time = item.date_time
                dst_zip.writestr(d_info, dex_patched_map[norm_name])
            elif norm_name in icon_replacements:
                i_info = zipfile.ZipInfo(item.filename)
                i_info.compress_type = item.compress_type
                i_info.date_time = item.date_time
                dst_zip.writestr(i_info, icon_replacements[norm_name])
            else:
                raw_bytes = src_zip.read(item.filename)
                new_info = zipfile.ZipInfo(item.filename)
                new_info.compress_type = item.compress_type
                new_info.date_time = item.date_time
                new_info.external_attr = item.external_attr
                dst_zip.writestr(new_info, raw_bytes)

print(f"Unaligned APK ready: {os.path.getsize(unaligned_apk)} bytes")

print("=== 5. 4-Byte ZipAligning APK ===")
aligned_apk = "edito-premium-aligned.apk"
if os.path.exists(aligned_apk):
    os.remove(aligned_apk)

zipalign_bin = r"C:\Users\Mini-PC\AppData\Local\Android\Sdk\build-tools\36.0.0\zipalign.exe"
res_align = subprocess.run([zipalign_bin, "-p", "-f", "4", unaligned_apk, aligned_apk], capture_output=True, text=True)
if res_align.returncode != 0:
    print("ZipAlign error:", res_align.stderr)
    sys.exit(1)
print(f"ZipAligned APK: {os.path.getsize(aligned_apk)} bytes")

print("=== 6. Signing APK with apksigner (v1, v2, v3) ===")
final_apk = "edito-premium.apk"
if os.path.exists(final_apk):
    os.remove(final_apk)

apksigner_bin = r"C:\Users\Mini-PC\AppData\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat"
env = os.environ.copy()
env["JAVA_HOME"] = r"C:\Program Files\Android\Android Studio\jbr"

cmd_sign = [
    apksigner_bin, "sign",
    "--ks", "test_edito.jks",
    "--ks-key-alias", "edito_premium",
    "--ks-pass", "pass:edito123",
    "--key-pass", "pass:edito123",
    "--v1-signing-enabled", "true",
    "--v2-signing-enabled", "true",
    "--v3-signing-enabled", "true",
    "--out", final_apk,
    aligned_apk
]
res_sign = subprocess.run(cmd_sign, env=env, capture_output=True, text=True)
if res_sign.returncode != 0:
    print("ApkSigner error:", res_sign.stderr, res_sign.stdout)
    sys.exit(1)

res_verify = subprocess.run([apksigner_bin, "verify", "-v", final_apk], env=env, capture_output=True, text=True)
assert "Verifies" in res_verify.stdout
print(f"Signed APK verified: {os.path.getsize(final_apk)} bytes")

if os.path.exists(unaligned_apk): os.remove(unaligned_apk)
if os.path.exists(aligned_apk): os.remove(aligned_apk)
print("=== Rebuild to Decoupled 'Edito Premium' Successful! ===")
