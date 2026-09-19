import os
import sys
import glob
import zipfile
import re
from collections import defaultdict, Counter

sys.stdout.reconfigure(encoding='utf-8')

def analyze_apk():
    apks = glob.glob('*.apk')
    if not apks:
        print("No APK found in directory!")
        return

    apk_path = apks[0]
    print(f"=== ANALYZING APK: {apk_path} ===")
    file_size_mb = os.path.getsize(apk_path) / (1024 * 1024)
    print(f"File Size: {file_size_mb:.2f} MB\n")

    with zipfile.ZipFile(apk_path, 'r') as z:
        namelist = z.namelist()
        print(f"Total files inside APK: {len(namelist)}")

        # 1. Inspect AndroidManifest.xml strings
        try:
            manifest_bytes = z.read('AndroidManifest.xml')
            # Basic binary XML string extractor
            # In binary xml, strings are stored in a string pool UTF-16 or UTF-8
            raw_strings = re.findall(rb'[\x20-\x7E]{4,}', manifest_bytes)
            decoded_strings = [s.decode('latin1') for s in raw_strings]
            
            # Find package name
            pkg = None
            for s in decoded_strings:
                if 'com.lemon.' in s or 'capcut' in s.lower() or 'bytedance' in s.lower():
                    pkg = s
                    break
            print(f"Detected Package / ID hint: {pkg}")
            
            # Extract permissions
            permissions = [s for s in decoded_strings if 'android.permission' in s]
            print(f"Permissions count: {len(set(permissions))}")
            print(f"Sample permissions: {sorted(list(set(permissions)))[:10]}")
        except Exception as e:
            print(f"Manifest parse error: {e}")

        # 2. Inspect Native Libraries (lib/)
        native_libs = defaultdict(list)
        for name in namelist:
            if name.startswith('lib/'):
                parts = name.split('/')
                if len(parts) >= 3:
                    abi = parts[1]
                    lib_name = parts[2]
                    info = z.getinfo(name)
                    native_libs[abi].append((lib_name, info.file_size))

        print("\n=== NATIVE ARCHITECTURES (ABIs) ===")
        for abi, libs in native_libs.items():
            print(f"ABI: {abi} -> {len(libs)} native libraries")
            # Sort by file size descending
            sorted_libs = sorted(libs, key=lambda x: x[1], reverse=True)
            print(f"  Top 15 Native Libraries in {abi}:")
            for lib_name, sz in sorted_libs[:15]:
                print(f"    - {lib_name:<35} ({sz / (1024*1024):.2f} MB)")

        # 3. Categorize Assets (assets/)
        asset_categories = defaultdict(list)
        ext_counter = Counter()
        model_files = []
        shader_files = []
        effect_files = []
        font_files = []
        lut_files = []
        audio_files = []

        for name in namelist:
            ext = os.path.splitext(name)[1].lower()
            ext_counter[ext] += 1

            if name.startswith('assets/'):
                parts = name.split('/')
                top_dir = parts[1] if len(parts) > 1 else 'root'
                asset_categories[top_dir].append(name)

                # Flag special file types
                lower = name.lower()
                if any(lower.endswith(x) for x in ['.tflite', '.onnx', '.model', '.pb', '.bin', '.param', '.net', '.weights']):
                    model_files.append(name)
                elif any(lower.endswith(x) for x in ['.glsl', '.frag', '.vert', '.comp', '.spv', '.shader']):
                    shader_files.append(name)
                elif 'lut' in lower or lower.endswith('.cube'):
                    lut_files.append(name)
                elif any(lower.endswith(x) for x in ['.ttf', '.otf']):
                    font_files.append(name)
                elif any(lower.endswith(x) for x in ['.mp3', '.wav', '.ogg', '.aac', '.m4a']):
                    audio_files.append(name)
                elif any(k in lower for k in ['effect', 'transition', 'filter', 'sticker', 'template']):
                    effect_files.append(name)

        print("\n=== FILE EXTENSIONS DISTRIBUTION ===")
        for ext, count in ext_counter.most_common(20):
            print(f"  {ext or '(none)'}: {count}")

        print("\n=== ASSET DIRECTORIES IN assets/ ===")
        for top_dir, files in sorted(asset_categories.items(), key=lambda x: len(x[1]), reverse=True)[:25]:
            print(f"  assets/{top_dir}/ -> {len(files)} files")

        print(f"\n=== MACHINE LEARNING / AI MODELS FOUND: {len(model_files)} ===")
        for m in model_files[:20]:
            print(f"  - {m} ({z.getinfo(m).file_size / 1024:.1f} KB)")

        print(f"\n=== SHADERS / GLSL PIPELINES FOUND: {len(shader_files)} ===")
        for s in shader_files[:25]:
            print(f"  - {s}")

        print(f"\n=== COLOR LUTS & 3D LOOKS FOUND: {len(lut_files)} ===")
        for l in lut_files[:20]:
            print(f"  - {l}")

        print(f"\n=== BUNDLED FONTS: {len(font_files)} ===")
        for f in font_files[:15]:
            print(f"  - {f}")

        print(f"\n=== BUNDLED AUDIO / SOUND FX: {len(audio_files)} ===")
        for a in audio_files[:15]:
            print(f"  - {a}")

        print(f"\n=== EFFECTS / TEMPLATES / TRANSITIONS / STICKERS COUNT: {len(effect_files)} ===")
        for e in effect_files[:20]:
            print(f"  - {e}")

if __name__ == '__main__':
    analyze_apk()
