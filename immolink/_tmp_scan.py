from pathlib import Path
path = Path('lib/features/tenant/presentation/pages/tenants_page.dart')
for i,line in enumerate(path.read_text().splitlines(),1):
    if "Text('" in line or 'const Text(' in line:
        print(f"{i:04d}: {line.strip()}")
