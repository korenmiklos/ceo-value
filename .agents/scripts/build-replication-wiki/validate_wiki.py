#!/usr/bin/env python3
import pathlib
import re
import sys

ROOT = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
RESERVED = {'index.md', 'log.md'}
TYPE_DIRS = {
    'data_source': 'Data source',
    'dataset': 'Dataset',
    'variable': 'Variable',
    'sample': 'Sample',
    'result': 'Result',
    'claim': 'Claim',
    'references': 'Reference',
    'build': 'Build record',
}
REL_TYPES = {
    ('Dataset', 'Dataset'): {'derived_from'},
    ('Dataset', 'Data source'): {'derived_from'},
    ('Variable', 'Dataset'): {'defined_in'},
    ('Variable', 'Variable'): {'computed_from'},
    ('Sample', 'Dataset'): {'selected_from'},
    ('Sample', 'Sample'): {'selected_from'},
    ('Sample', 'Variable'): {'depends_on'},
    ('Result', 'Sample'): {'uses_sample'},
    ('Result', 'Variable'): {'uses_variable'},
    ('Claim', 'Result'): {'supported_by'},
}

def frontmatter(text):
    if not text.startswith('---\n'):
        return None, None
    end = text.find('\n---\n', 4)
    if end <  0:
        return None, None
    fm = text[4:end]
    body = text[end+5:]
    return fm, body

def yaml_lines(fm):
    depth = 0
    key = None
    out = []
    for raw in fm.splitlines():
        line = raw.rstrip()
        if depth == 0:
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*:', line):
                key = line.split(':', 1)[0]
                out.append((depth, line, key))
            else:
                out.append((depth, line, key))
        else:
            out.append((depth, line, key))
        if '[' in line:
            depth += line.count('[') - line.count(']')
        if '{' in line:
            depth += line.count('{') - line.count('}')
    return out

def check_file(p):
    rel = p.relative_to(ROOT)
    errs = []
    text = p.read_text()
    fm, body = frontmatter(text)
    if fm is None:
        return [rel, 'no-frontmatter', 'file lacks --- delimiters']
    lines = yaml_lines(fm)
    has_type = False
    for depth, line, key in lines:
        if depth == 0 and key == 'type':
            has_type = True
            val = line.split(':', 1)[1].strip()
            if not val:
                errs.append((rel, 'empty-type', line.strip()))
    if not has_type:
        errs.append((rel, 'missing-type', 'no type:'))
    return errs
def main():
    errs = []
    files = 0
    for p in sorted(ROOT.rglob('*.md')):
        if p.name in RESERVED:
            continue
        files +=  1
        errs.extend(check_file(p))
    print('scanned', files, 'files', 'errors', len(errs))
    for e in errs:
        print('  ', e[0], '|', e[1], '|', e[2])
    return 0 if not errs else 1

if __name__ == '__main__':
    sys.exit(main())