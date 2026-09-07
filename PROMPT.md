# Claim Evaluation Prompt

You are evaluating a scientific claim about computations in this codebase.

## Process

1. **Start in openwiki** — Read the relevant wiki page(s) first. The wiki is the entry point but not ground truth.

2. **Trace to source code** — Follow wiki citations, Makefile rules, and script chains to the actual `.do`, `.jl`, or `.ado` files that would implement the claimed logic. External Stata packages (`.ado` files installed via `ssc install`, `github install`, etc.) are part of the active execution path even when they live outside the repo (e.g., in the Stata personal or system ado-path).

3. **Verify execution path** — Confirm the script is **actually invoked**:
   - Check Makefile recipes for `$(STATA) -b do <script>` or equivalent invocation
   - Check for `do`, `run`, or `include` calls in upstream scripts
   - A script listed as a prerequisite (`CODELIB`, `DATALIB`) or drawn in a pipeline diagram may be dead code — trace at least one execution path
   - If matching code exists but the script is never called, note **dormant code**

4. **Distinguish active vs. dormant** — If the claim describes a pipeline step and the implementing script is never executed, the code exists but does not describe the pipeline. **Dormant code yields UNCERTAIN**, not FALSE.

## Verdicts

- **TRUE**: Code matching the claim exists and is part of the active execution path.
- **FALSE**: The claim contradicts the code or is not implemented anywhere in the active pipeline.
- **UNCERTAIN**: Insufficient evidence, or matching code exists but is dormant (not executed). Include a statement that, if true, would make the original claim true.

## Evidence

For every verdict, cite:
- The wiki page(s) consulted
- The source file(s), line numbers, and relevant code
- Execution path evidence (Makefile recipe, do/run/include call, or absence thereof)