import json
from pathlib import Path
base = Path('lib/l10n')
files = ['app_en.arb','app_de.arb','app_fr.arb','app_it.arb']
ref = set(json.load(open(base / files[0], encoding='utf-8')).keys())
for file in files[1:]:
    keys = set(json.load(open(base / file, encoding='utf-8')).keys())
    missing = sorted(ref - keys)
    extra = sorted(keys - ref)
    print(f"=== {file} ===")
    print(f"missing {len(missing)}")
    for key in missing:
        print("  ", key)
    print(f"extra {len(extra)}")
    for key in extra:
        print("  ", key)
