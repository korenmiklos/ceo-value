---
type: Reference
title: Debiased R2 table - full sample
description: Evidence from papers/econometrics/table/r2s_full.tex, R2 decomposition.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Debiased R2 table - full sample

## Source

- Path: `papers/econometrics/table/r2s_full.tex`
- SHA-256: `66d081dda073a0c423dcd7cbee64f9556f3a8bec47ac55e04b022081ccc67135`
- Inspected: exact source slices below

## Excerpt

### Full file verbatim
```text
\begin{tabular}{l*{5}{c}}
\hline\hline
 Estimate & lnR & lnL & lnK & ROA & lnRL \\
\hline
\addlinespace $ R^2$ (OLS) & $0.679$ & $0.675$ & $0.657$ & $0.647$ & $0.649$ \\
$ R^2$ (debiased) & $0.314$ & $0.263$ & $0.273$ & $0.177$ & $0.292$ \\
\hline\hline
\end{tabular}
```
## Notes

- The debiased R2 are roughly half the OLS R2 for most outcomes  consistent with the paper's claim that naive estimates overstate CEO importance by about 2..8x("on average").
- Produced by `papers/econometrics/src/exhibit/application_r2s.do` from `data/atet_full_full_{outcome}-{outcome}.csv` artifacts.
