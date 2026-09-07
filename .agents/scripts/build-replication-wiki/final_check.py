import pathlib
import re
import yaml

ROOT = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
RESERVED = {'index.md', 'log.md'}

files = 0
yaml_bad = 0
dangling = []
no_type = []
for p in sorted(ROOT.rglob('*.md')):
    files += 1
    t = p.read_text()
    if not t.startswith('---'):
        print('NOFM', p.relative_to(ROOT))
        continue
    fm = t.split('---', 2)[1]
    try:
        d = yaml.safe_load(fm) or {}
        if 'type' not in d and p.name not in RESERVED:
            no_type.append(str(p.relative_to(ROOT)))
    except Exception as e:
        yaml_bad += 1
        print('YAML', str(p.relative_to(ROOT)), str(e)[:70])
    for m in re.finditer(r'\]\(([^)#]+\.md)\)', t):
        val = m.group(1)
        if val.startswith('http'):
            continue
        tgt = (p.parent / val).resolve()
        if not tgt.exists():
            dangling.append((str(p.relative_to(ROOT)), val))

print('files', files, 'yaml_bad', yaml_bad, 'no_type', len(no_type))
for n in no_type:
    print('  notype', n)
print('dangling', len(dangling))
for d in dangling:
    print('  ', d)

# counts by type
from collections import Counter
c = Counter()
for p in sorted(ROOT.rglob('*.md')):
    t = p.read_text()
    if t.startswith('---'):
        fm = t.split('---', 2)[1]
        d = yaml.safe_load(fm) or {}
        c[d.get('type', 'none')] += 1
print('type counts', dict(c))