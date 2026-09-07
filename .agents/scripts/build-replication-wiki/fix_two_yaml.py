import pathlib
root = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
# table2_atet.md: locator 'Table 2 section' colons -- quote
p = root / 'result' / 'table2_atet.md'
t = p.read_text()
t = t.replace('    locator: Table 2 section', '    locator: "Table 2 section"')
p.write_text(t)
# extract_samples.md: relations block needs evidence list per predicate
p = root / 'sample' / 'extract_samples.md'
t = p.read_text()
t = t.replace('    basis: declared\n    evidence: [ext_code]\n    qualifiers: input file input/bloom-et-al-2012/replication.dta absent in checkout',
              '    basis: declared\n    evidence: [ext_code]')
p.write_text(t)
print('done')