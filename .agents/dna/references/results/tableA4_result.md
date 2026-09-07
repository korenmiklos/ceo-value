---
type: Reference
title: Table A4 - Share of Variance Attributed to CEO Change
description: Evidence from papers/application/table/tableA4.tex, variance decomposition.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Table A4 - Share of Variance Attributed to CEO Change

## Source

- Path: `papers/application/table/tableA4.tex`
- SHA-256: `cd5ce71851dd24c9cc898e9037da66ab69891ec49dffad10fb7c6cc8e9ba4cb9`
- Inspected: exact source slices below

## Excerpt

### Full file verbatim
```text

\begin{table}[htbp]
\centering
\caption{Share of Variance Attributed to CEO Change}
\vspace{.2cm}
\label{tab:var_share}
\begin{tabular}{lccc}
\toprule
Firm age & Total Variance Growth & Naive ANOVA share & Adjusted ANOVA share \\
\hline
4 &     0.024 &  0.544 &  0.451 \\
8 &     0.033 &  0.625 &  0.368 \\
12 &     0.035 &  0.620 &  0.269 \\ \bottomrule
\end{tabular}
\begin{minipage}{14cm}
\vspace{.2cm}
\footnotesize \textit{Notes:} The table presents the total variance growth of TFP since the second full year after firm establishment (Column 1), the uncorrected contribution of CEO change to total variance growth (Column 2) and the corrected contribution (Column 3). 
\end{minipage}
\end{table}

```
## Notes

- The paper text cites the 10-year figures as 62% naive 29% adjusted; the table shows firm-age 8 and 12 bracketing that row (0.625, 0.368 at age 8; 0.620, 0.269 at age  12).
- The producing script for this table is not located in the checkout (grep found no `.do` writing tableA4); it is likely a manual/Excel-adjacent artifact.
