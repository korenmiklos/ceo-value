import pathlib
p = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna/dataset/surplus.md')
t = p.read_text()
old2 = 'listed in the observed temp inventory per the [build record](../build/2026-09-07/record.md.'
new2 = 'listed in the observed temp inventory per the [build record](../build/2026-09-07/record.md' + chr(41) + '.'
if old2 in t:
    t = t.replace(old2, new2)
    p.write_text(t)
    print('replaced')
else:
    print('pattern not found')
o = t.count(chr(40)
c = t.count(chr(41))
print('paren', o, c))
