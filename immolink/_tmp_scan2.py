from pathlib import Path
path = Path('lib/features/tenant/presentation/pages/tenant_services_booking_page.dart')
for i,line in enumerate(path.read_text().splitlines(),1):
    if "'" in line and 'Text(' in line:
        print(f"{i:04d}: {line.strip()}")
