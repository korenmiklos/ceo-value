#!/usr/bin/env python3
import pathlib
root = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
keep = set()
keep.add('references/paper_application.md')
keep.add('references/estimation_doc.md')
keep.add('references/readme.md')
keep.add('references/paper_econometrics.md')
table = dict()
table['\u00d7'] = 'x'
table['\u2014'] = '-'
table['\u2013'] = '-'
table['\u2019'] = "'"
table['\u2018'] = "'"
table['\u201c'] = '"'
table['\u201d'] = '"'
table['\ufeff'] = ''
table['\u200b'] = ''
table['\u00a0'] = ' '
def fix(s):
    out = []
    for ch in s:
        if ch in table:
            out.append(table[ch])
        elif ord(ch) < 128:
            out.append(ch)
        else:
            out.append('')
    return ''.join(out)
count = 0
for p in root.rglob('*.md'):
    rel = str(p.relative_to(root))
    if rel in keep:
        continue
    b = p.read_bytes()
    flagged = (b.count(b'\xef\xbb\xbf') > 0) or any(x >= 0x80 for x in b)
    if flagged:
        p.write_text(fix(p.read_text()))
        count +=  1
print('fixed', count)