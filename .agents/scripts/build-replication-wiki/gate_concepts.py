import pathlib
import yaml
ROOT = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
GLOBS = ['data_source/*.md', 'dataset/*.md', 'variable/*.md', 'result/*.md', 'sample/*.md', 'claim/*.md']
LP1 = chr(40)
RP1 = chr(41)
problems = 0
for g in GLOBS:
    for p in sorted(ROOT.glob(g)):
        name = str(p.relative_to(ROOT))
        t = p.read_text()
        issues = []
        fm = t.split('---', 2)[1] if t.startswith('---') else ''
        try:
            yaml.safe_load(fm)
        except Exception as e:
            issues.append('yaml:' + str(e)[:60])
        for i, ln in enumerate(t.splitlines(), 1):
            o = ln.count(LP1)
            c = ln.count(RP1)
            if i > 1 and o != c:
                issues.append('line' + str(i) + ' paren' + str(o) + '/' + str(c))
        if t.count('.md.') > 0:
            issues.append('md-dot:' + str(t.count('.md.')))
        if t.count('\ufffd') > 0 or any(ord(ch) > 0x2500 for ch in t):
            issues.append('odd-chars')
        if issues:
            problems += 1
            print('##', name)
            for it in issues[:6]:
                print('   ', it)
print('files with issues', problems)