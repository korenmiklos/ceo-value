---
type: Dataset
title: Manager facts tables
description: temp/manager-facts.dta (manager-level facts)and temp/manager-firm-facts.dta (firm-manager facts;, built from registry demographics.)
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: mf_code
    resource: ../references/code/manager_facts_do.md
    locator: Lines  1-13
  - id: logs
    resource: ../references/logs.md
    locator: manager-facts.log observed run
relations:
  - predicate: derived_from
    target: ../data_source/cegjegyzek_lts.md
    basis: declared
    evidence: [mf_code]
---

# Manager facts tables

## Units of observation

- `temp/manager-facts.dta`: one row per person (`person_id`).
- `temp/manager-firm-facts.dta`: one row per firm-person pair (distinct `frame_id_numeric x person_id`..

## Construction

`lib/create/manager-facts.do` keeps `frame_id_numeric, person_id, male, birth_year, manager_category, owner` from the raw registry;, defines `hungarian_name = !missing(male)`, drops duplicates,[^mf_code] and splits outputs:

- firm-manager facts (drop demographics)  `temp/manager-firm-facts.dta`
- manager-level facts: `collapse (firstnm) male birth_year (max) hungarian_name, by(person_id)`  `temp/manager-facts.dta`.



## Notes

- `hungarian_name` proxies Hungarian-name status by male non-missing - consistent with the comment "we only infer gender from Hungarian names" in [variables.do](../references/code/variables_do.md).
- Logs attest to runs (manager-facts.log`.



[^mf_code]: [Manager facts construction code](../references/code/manager_facts_do.md).
[^logs]: [Stata execution logs](../references/logs.md).
