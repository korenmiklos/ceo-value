import pathlib
p = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna/dataset/surplus.md')
lines = p.read_text().splitlines()
out = []
skip = False
for i, ln in enumerate(lines):
    if i in (29, 30, 31):
        continue
    if ln.strip() == '## Fields attested by consumers':
        out.append('## Fields attested by extractor')
        out.append('')
        out.append('[extract.do](../references/code/extract_do.md), lines   ﻿64-101, uses `temp/surplus.dta` and collapses by firm-and-period: `TFP` plus `person_id` and `chi` via `firstnm`; `T_spell` counted per transition period, with `year`, `frame_id_numeric`, `ceo_spell` as grouping fields. The file therefore carries these fields per the extractor locator; the producing script `surplus.do` is missing, so native generation steps are untraceable.')
        continue
    out.append(ln)
p.write_text('\n'.join(out) + '\n')
print("done", len(out))