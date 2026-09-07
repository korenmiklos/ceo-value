## Concepts and relations

Create concepts around independently useful review targets:

| Concept | Typical instance | Main contents |
|---|---|---|
| Data source | Administrative employer records | Origin, access, coverage, documentation |
| Dataset | Clean firm-year panel | Unit of observation, keys, schema, construction |
| Variable | Log real sales | Definition, units, labels, value and sample ancestry |
| Sample | Baseline estimation sample | Eligibility, filters, merge and missingness exclusions |
| Result | Table 3, column 2 | Specification, variables, sample, code and output locations |
| Claim | Exporters pay higher wages | Paper statement, supporting results, assessment and evidence |

Start with a small set of typed relations:

| From | Relation | To |
|---|---|---|
| Dataset | `derived_from` | Dataset or Data source |
| Variable | `defined_in` | Dataset |
| Variable | `computed_from` | Variable |
| Sample | `selected_from` | Dataset or Sample |
| Sample | `depends_on` | Variable affecting inclusion |
| Result | `uses_sample` | Sample |
| Result | `uses_variable` | Variable, with role such as outcome, regressor, weight, cluster, fixed effect |
| Claim | `supported_by` | Result offered as evidence |

Store typed relations in an extension field and explain them in the Markdown body, generating both from the same records. Derive inverse links rather than storing duplicates. Attach evidence references and qualifiers to assertions and edges.

A variable's identity needs its dataset and construction context. Overwritten datasets can represent distinct states. An estimation sample can differ from the saved dataset. Claims' `supported_by` links record the paper's argument, not a reviewer's endorsement.

Start from supplied claims and reported results and follow dependencies. Shared datasets, variables, and samples get reusable concepts; routine temporary intermediates and individual operations can remain inside lineage slices. Claim extraction remains outside #144's scope.

## Evidence and verification

Distinguish what documentation declares, what extraction infers, what execution observes, and what remains unresolved or contradictory. For example, a declared merge cardinality is different from an observed uniqueness check.

Preserve DNA's `runtime` versus `unknown` distinction. It concerns whether lineage is resolved, independently of OKF's record of who generated or verified a concept. Structural conformance does not establish semantic correctness.

Source pointers should be anchored to content hashes or an immutable snapshot. The package need not use Git.

Retain the distinction between the knowledge representation and the policy controlling exposure:

- Source code execution is part of evidence. A script listed as a dependency or drawn in a pipeline diagram is not proof it runs—trace actual invocation (Makefile recipes, do/run/include calls). Verification is distinct from downstream representation.
- OKF represents available knowledge and evidence.
- Context selection supplies a bounded packet for one claim.
- A verifier requests specific missing facts.
- Prerequisites can be resolved separately, returning conclusions and evidence without importing the entire investigation.

Insufficient context can also cause false positives. Missing evidence must produce a request or uncertainty, not an allegation of error. The objective is sufficient relevant context, not simply fewer tokens.

Good producers and portable review skills may reduce harness-specific integration work. They do not replace #144's deterministic scheduling, typed verdict propagation, budget enforcement, or evidence boundaries where those guarantees are required.

## Eval benefit: readable evidence packets

A major benefit is making the context-to-verdict relationship inspectable by humans and evaluating agents. Preserve for each attempt:

- The claim.
- The exact concept versions and excerpts supplied, including truncations.
- Additional evidence requests and whether they were fulfilled.
- The verdict and a concise evidence-linked justification.

This is a reviewable justification, not a requirement to expose private model reasoning.

When a false positive occurs, an evaluator can assess whether the producer was wrong, necessary evidence was omitted, irrelevant context was supplied, or adequate evidence was misinterpreted. A mutable bundle alone is insufficient: preserve exactly what the verifier saw.
