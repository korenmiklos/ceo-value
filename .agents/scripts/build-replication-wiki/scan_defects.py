#!/usr/bin/env python3
import pathlib
import re

ROOT = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
META = re.compile(r'^\s*(title|locator|description):')
MDFN = re.compile(r'\]\([^)]*\.md\.$')

def main():
    hits = 0
    for p in sorted(ROOT.rglob('*.md')):
        rel = str(p.relative_to(ROOT))
        bad = []
        for i, ln in enumerate(p.read_text().splitlines(), 1):
            if META.match(ln):
                o = ln.count('('); c = ln.count(')')
                if o != c:
                    bad.append((i, 'paren ' + ln[:100]))
            if MDFN.search(ln):
                bad.append((i, 'md-dot ' + ln[:100]))
        if bad:
            hits +=   1
            print(rel)
            for i, d in bad:
                print('   ', i, d)
    print('files with issues:', hits)

if __name__ == '__main__':
    main()