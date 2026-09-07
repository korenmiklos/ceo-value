#!/usr/bin/env python3
import pathlib
import re
import sys

ROOT = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
RESERVED = {'index.md', 'log.md'}

def get_type(p):
    text = p.read_text()
    if not text.startswith('---'):
        return None
    end = text.find('\n---', 4)
    fm = text[:end]
    for ln in fm.splitlines():
        if ln.startswith('type:'):
            return ln[5:].strip()
    return None

def resolve(ref, base_p):
    ref = ref.split('#', 1)[0].split('?', 1)[0]
    if ref.startswith('../'):
        return (base_p.parent / ref).resolve()
    return (base_p.parent / ref).resolve()

def main():
    errs = []
    files = 0
    for p in sorted(ROOT.rglob('*.md')):
        if p.name in RESERVED:
            continue
        files +=   1
        text = p.read_text()
        # relations targets
        for m in re.finditer(r'^  {2}- predicate: (\w+)$', text, re.M):
            # we need the block; simple approach: find 'target:' lines following a relations: header
            pass
        # generic target:/resource: link resolution
        for m in re.finditer(r'^(  +)(target|resource): ([^\s]+)$', text, re.M):
            val = m.group(3).strip()
            if not val:
                continue
            tgt = resolve(val, p)
            if not tgt.exists():
                errs.append((str(p.relative_to(ROOT), 'dangling-' + m.group(2), val))
        # markdown links
        for m in re.finditer(r'\[([^\]]+)\]\(([^)]+)\)', text):
            val = m.group(2)
            if val.startswith(('http://', 'https://', 'mailto:')):
                continue
            tgt = resolve(val, p)
            if not tgt.exists():
                errs.append((str(p.relative_to(ROOT), 'dangling-link', val))
        # footnote links [^id]: path.md
        for m in re.finditer(r'^\[\^([^\]]+)\]:\s*(\S+)$', text, re.M):
            val = m.group(2)
            tgt = resolve(val, p)
            if not tgt.exists():
                errs.append((str(p.relative_to(ROOT), 'dangling-footnote', val))
        # relations semantic block check: extract lines under 'relations:' list
        if re.search(r'^relations:', text, re.M):
            block = text.split('relations:', 1)[1].split('\n---', 1)[0]
            # crude: every '- predicate:' line within 12 lines
            preds = [x for x in re.findall(r'- predicate: (\w+)', block)]
            for pr in preds:
                if pr not in {'derived_from', 'defined_in', 'computed_from', 'selected_from', 'depends_on', 'uses_sample', 'uses_variable', 'supported_by'}:
                    errs.append((str(p.relative_to(ROOT), 'bad-predicate', pr))
            # every target within block must have basis and evidence
            if '- basis:' not in block:
                errs.append((str(p.relative_to(ROOT), 'relations-no-basis', 'relations list lacks basis entries')))
    print('scanned', files, 'files', 'errors', len(errs))
    for e in errs:
        print('  ', e[0], '|', e[1], '|', e[2])
    return 0 if not errs else 1

if __name__ == '__main__':
    sys.exit(main())