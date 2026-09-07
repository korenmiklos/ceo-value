#!/usr/bin/env python3
import pathlib

ROOT = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')

def main():
    for d in ['data_source', 'dataset', 'variable', 'result']:
        print('####', d.upper())
        for p in sorted(ROOT.glob(d + '/*.md)):
            t = p.read_text()
            if t.startswith('---'):
                fm = t.split('---', 2)[1]
            else:
                fm = t[:400]
            print('====', p.name)
            print(fm[:700].replace(chr(10), ' | '))

main()