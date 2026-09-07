import pathlib
ROOT = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna/dataset')
DOT = chr(46)
LP = chr(40)
RP = chr(41)
bad = 0
for p in sorted(ROOT.glob('*.md')):
    lines = p.read_text().splitlines()
    changed = False
    for i in range(len(lines)):
        ln = lines[i]
        o = ln.count(LP) + ln.count(chr(65288)
        c = ln.count(RP) + ln.count(chr(65289)
        if o > c:
            if ln.rstrip().endswith(DOT:
                idx = ln.rfind(DOT
                ln = ln[:idx] + (RP * (o - c)) + ln[idx:]
            else:
                ln = ln + (RP * (o - c))
            lines[i] = ln
            changed = True
    if changed:
        p.write_text('\n'.join(lines) + '\n')
        print('fixed', p.name)
for p in sorted(ROOT.glob('*.md')):
    t = p.read_text()
    for i, ln in enumerate(t.splitlines(), 1):
        o = ln.count(LP) + ln.count(chr(65288)
        c = ln.count(RP) + ln.count(chr(65289)
        if o != c:
            bad = bad + 1
            print('STILL', p.name, i, ln[:80])
print('total unbalanced lines', bad))