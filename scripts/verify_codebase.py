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

    # Const AppTypography check: AppTypography getters cannot be used in const expressions
    for m in re.finditer(r"\bconst\b", content):
        start = m.start()
        sub = content[start:start+400]
        parens = 0
        opened = False
        expr = []
        for char in sub:
            expr.append(char)
            if char == '(':
                parens += 1
                opened = True
            elif char == ')':
                parens -= 1
                if opened and parens == 0:
                    break
            elif char == ';' and parens == 0:
                break
        expr_str = "".join(expr)
        if "AppTypography" in expr_str:
            line_no = content[:start].count('\n') + 1
            errors.append(f'{df}:{line_no}: invalid const wrapping AppTypography')

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
