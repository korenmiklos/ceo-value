import pathlib
import yaml
root = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
CONCEPT_DIRS = ['data_source', 'dataset', 'variable', 'sample', 'result', 'claim']
# 1) quote every plain description/title scalar containing colon-space or leading specials
for d in CONCEPT_DIRS:
    for p in sorted((root / d).glob('*.md')):
        t = p.read_text()
        lines = t.splitlines()
        changed = False
        for i, ln in enumerate(lines):
            for key in ('description:', 'title:', 'locator:'):
                if ln.startswith(key):
                    val = ln[len(key):].strip()
                    if val.startswith('"'): 
                        continue
                    if ': ' in val or val.startswith('-'):
                        lines[i] = key + ' "' + val + '"'
                        changed = True
        if changed:
            p.write_text('\n'.join(lines) + '\n')
print('quoting pass done')
# 2) YAML validate all concepts
bad = 0
for d in CONCEPT_DIRS:
    for p in sorted((root / d).glob('*.md')):
        t = p.read_text()
        fm = t.split('---', 2)[1] if t.startswith('---') else ''
        try:
            yaml.safe_load(fm)
        except Exception as e:
            bad += 1
            print('YAML', p.relative_to(root), str(e)[:80])
print('yaml bad files', bad)