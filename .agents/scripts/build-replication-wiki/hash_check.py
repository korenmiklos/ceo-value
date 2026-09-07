import hashlib
import pathlib
import re
import yaml

ROOT = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
REPO = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value')

bad_hash = []
miss_src = []
bad_rel = []
for p in sorted((ROOT / 'references').rglob('*.md')):
    t = p.read_text()
    # Source path + SHA-256 in frontmatter/body
    m = re.search(r'Path: `([^`]+)`', t)
    h = re.search(r'SHA-256: `([0-9a-f]{64})`', t)
    if not m or not h:
        continue
    src = REPO / m.group(1)
    if not src.exists():
        miss_src.append((str(p.relative_to(ROOT)), m.group(1)))
        continue
    dig = hashlib.sha256(src.read_bytes()).hexdigest()
    if dig != h.group(1):
        bad_hash.append((str(p.relative_to(ROOT)), h.group(1)[:12], dig[:12]))

rel_bad = 0
for p in ROOT.rglob('*.md'):
    if p.name in ('index.md', 'log.md'):
        continue
    t = p.read_text()
    if not t.startswith('---'):
        continue
    fm = t.split('---', 2)[1]
    try:
        d = yaml.safe_load(fm) or {}
    except Exception:
        continue
    for rel in d.get('relations', []) or []:
        tg = rel.get('target')
        if not tg:
            continue
        tgt = (p.parent / tg).resolve()
        if not tgt.exists():
            rel_bad += 1
            if rel_bad <= 10:
                print('RELBAD', str(p.relative_to(ROOT)), tg)

print('hash bad', len(bad_hash), 'missing src', len(miss_src))
for b in bad_hash[:10]:
    print('  ', b)
for b in miss_src[:10]:
    print('  MISS', b)
print('relation target bad', rel_bad)