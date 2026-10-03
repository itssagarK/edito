import zipfile, json

with zipfile.ZipFile('capEditor.zip', 'r') as z:
    data = json.loads(z.read('assets/default_tools_config_v5.json').decode('utf-8'))
    for cat in data.get('categories', []):
        print(f"Category: {cat.get('title')} ({cat.get('category_id')})")
        for t in cat.get('tools', []):
            print(f"   - {t.get('tool_id')}: {t.get('name')}")
    print("\n--- Home Categories ---")
    for cat in data.get('home_categories', []):
        print(f"Home Category: {cat.get('title')} ({cat.get('category_id')})")
        for t in cat.get('tools', []):
            print(f"   - {t.get('tool_id')}: {t.get('name')}")
