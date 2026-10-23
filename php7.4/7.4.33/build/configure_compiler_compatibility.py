"""Change generated compiler flags only; upstream PHP source remains untouched."""
from pathlib import Path
import sys

path = Path(sys.argv[1]).resolve(strict=True)
if path.name.lower() != 'makefile':
    raise SystemExit('Expected a generated PHP Makefile')
text = path.read_text()
count = text.count('/d2FuncCache1')
path.write_text(text.replace('/d2FuncCache1', ''), newline='\n')
print('Removed /d2FuncCache1 from generated Makefile: ' + str(count) + ' occurrence(s)')
