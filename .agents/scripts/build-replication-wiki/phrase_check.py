import pathlib
TARGET = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna/data_source/merleg_lts.md')
b = TARGET.read_bytes()
checks = [
    (b'M\xc3\xa9rleg', 'accented Merleg'),
    (b'`-', 'hyphen-after-backtick'),
    (b'` -', 'spaced-hyphen'),
    (b'the file consumed', 'the-file'),
    (b'not consumed by traced scripts', 'not-consumed'),
    (b'state, foreign', 'state-foreign'),
    (b'cannot be made public', 'cannot-public'),
]
for needle, label in checks:
    print(label, needle in b)
print('size', len(b))