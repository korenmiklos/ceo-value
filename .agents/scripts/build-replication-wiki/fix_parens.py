import pathlib
root = pathlib.Path('/Users/koren/Tresorit/Mac/projects/ceo-value/.agents/dna')
R = [
    ('dataset/analysis_sample.md', '5. Drop sector 9 (Finance; mining mentioned in comment but not coded.',
     '5. Drop sector 9 (Finance; mining mentioned in comment but not coded).'),
    ('dataset/analysis_sample.md', '6. Drop firms never reaching 3 employment (`max_employment` under 3.',
     '6. Drop firms never reaching 3 employment (`max_employment` under 3).'),
    ('dataset/analysis_sample.md', 'Observed log run (old naming, wrote `temp/analysis-sample.dta`; deletion sequence above. Paper (July 2026 counts 471 thousand firms and 4,363,067 firm-years. README cites different-era counts as of an older pipeline.',
     'Observed log run (old naming), wrote `temp/analysis-sample.dta`; deletion sequence above. Paper (July 2026) counts 471 thousand firms and 4,363,067 firm-years. README cites different-era counts as of an older pipeline.'),
    ('dataset/balance_clean.md', 'title: Balanced sheet cleaning output (temp/balance.dta \u2192',
     'title: Balance sheet cleaning output (temp/balance.dta)'),
    ('dataset/edgelist.md', '    locator: edgelist.log (observed run matched 1,058,307 firm-person pairs',
     '    locator: "edgelist.log (observed run matched 1,058,307 firm-person pairs)"'),
    ('dataset/manager_facts.md', '- `temp/manager-firm-facts.dta`: one row per firm-person pair (distinct `frame_id_numeric x person_id`..',
     '- `temp/manager-firm-facts.dta`: one row per firm-person pair (distinct `frame_id_numeric x person_id`).'),
    ('dataset/manager_facts.md', "- Logs attest to runs (manager-facts.log`.",
     "- Logs attest to runs (manager-facts.log)."),
    ('dataset/manager_value.md', '    locator: manager_value.log (saved manager_value.dta and manager_value_spell.dta',
     '    locator: "manager_value.log (saved manager_value.dta and manager_value_spell.dta)"'),
    ('variable/capital.md', '- This `capital` variable itself is not referenced downstream in traced scripts (constructed butunused subsequently - a dormant intermediate`',
     '- This `capital` variable itself is not referenced downstream in traced scripts (constructed but unused subsequently, a dormant intermediate).'),
    ('variable/employment.md', "- `lnL = ln(employment)` (labor input`.[^var_code]",
     "- `lnL = ln(employment)` (labor input).[^var_code]"),
    ('variable/employment.md', '- Unit: persons (declared; not unit-verified against raw metadata`.',
     '- Unit: persons (declared; not unit-verified against raw metadata).'),
    ('variable/lnK.md', '# Log tangible assets (lnK',
     '# Log tangible assets (lnK)'),
    ('variable/lnK.md', '`lnK = ln(tangible_assets)`.[^var_code] Note this uses tangible assets directly (not the derived `capital` variable`',
     '`lnK = ln(tangible_assets)`.[^var_code] Note this uses tangible assets directly (not the derived `capital` variable).'),
    ('variable/lnK.md', '- Control in revenue-function models (model 1 etc.,[^rf_code].',
     '- Control in revenue-function models (model 1 etc.),[^rf_code].'),
    ('variable/lnK.md', '- Outcome in econometrics event studies (`lnK` ATET and CSV outputs`.',
     '- Outcome in econometrics event studies (`lnK` ATET and CSV outputs).'),
]
for name, old, new in R:
    p = root / name
    t = p.read_text()
    if old in t:
        t = t.replace(old, new)
        p.write_text(t)
        print('ok', name, old[:40])
    else:
        print('MISS', name, old[:40])