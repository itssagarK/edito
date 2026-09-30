import os
import re

errors = []
dart_files = []
for root, dirs, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            dart_files.append(os.path.join(root, f))
for root, dirs, files in os.walk('test'):
    for f in files:
        if f.endswith('.dart'):
            dart_files.append(os.path.join(root, f))

for df in dart_files:
    with open(df, 'r', encoding='utf-8') as f:
        content = f.read()

    # Rule checks
    if 'withValues(' in content:
        errors.append(f'{df}: uses withValues')
    if 'filledStyleFrom(' in content:
        errors.append(f'{df}: uses filledStyleFrom')
    if 'AppColors.surfaceLight' in content:
        errors.append(f'{df}: uses AppColors.surfaceLight')

    # Import rule: widgets/ to models/ or services/ within that feature require ../../
    normalized_path = df.replace('\\', '/')
    if '/presentation/widgets/' in normalized_path:
        lines = content.splitlines()
        for idx, line in enumerate(lines):
            if re.search(r"import\s+['\"]\.\./(models|services)/", line):
                errors.append(f'{df}:{idx+1}: invalid single ../ import: {line}')

print(f'Scanned {len(dart_files)} Dart files.')
if errors:
    print(f'Found {len(errors)} issues:')
    for e in errors:
        print(' -', e)
    exit(1)
else:
    print('100% CLEAN: All files adhere to strict architecture and import rules!')
    exit(0)
