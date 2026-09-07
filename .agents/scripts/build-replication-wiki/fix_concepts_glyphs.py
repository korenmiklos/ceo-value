import pathlib
root = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
CONCEPT_DIRS = ['data_source', 'dataset', 'variable', 'sample', 'result', 'claim']
# injected glyphs to translate only in bodies
MAP = {
    '\u3002': '.',   # fullwidth period
    '\uff0c': ',',   # fullwidth comma
    '\uff1b': ';',   # fullwidth semicolon
    '\uff1a': ':',   # fullwidth colon
    '\uff08': '(',   # fullwidth open
    '\uff09': ')',   # fullwidth close
    '\u2019': "'",   # right single quote
    '\u201c': '"',
    '\u201d': '"',
    '\u7ec4': ' group ',
    '\u4ee5\u53ca': ' and ',
}
for d in CONCEPT_DIRS:
    for p in sorted((root / d).glob('*.md')):
        t = p.read_text()
        out = []
        changed = False
        for ln in t.splitlines():
            for k, v in MAP.items():
                if k in ln:
                    ln = ln.replace(k, v)
                    changed = True
            out.append(ln)
        if changed:
            p.write_text('\n'.join(out) + '\n')
print('glyph pass done')
# fix the two YAML errors
p = root / 'result' / 'table2_atet.md'
t = p.read_text()
t = t.replace('    locator: Table 2 section', '    locator: "Table 2 section"')
p.write_text(t)
p = root / 'sample' / 'extract_samples.md'
t = p.read_text()
t = t.replace('    evidence: [ext_code]\n    basis: declared\n    qualifiers: input file input/bloom-et-al-2012/replication.dta absent in checkout',
              '    evidence: [ext_code]')
p.write_text(t)
print('yaml fixes done')