---
id: 1
type: note
created: 2026-09-29
related: []
---

# Executive talent allocation review

Solo review session. Reviewed the paper "Better executives work at better firms: Identifying talent sorting from mobility networks" by Chu C.O.C. Focused on rewriting the abstract and introduction for clarity, precision, and active voice.

## Abstract: rewrite the first three sentences

The abstract opens too densely, introducing four overlapping concepts (allocation, complementarity, sorting, mobility) in the first two sentences with no grounding for the reader. "Latent variation" appears without explanation.

The strong sentence to keep is: "Covariance decay with network distance identifies the correlation between executive talent and firm productivity." It uses well-defined nouns and says what the method does. The correlation of 0.5 and the 13% revenue loss from random reassignment (correctly rounded) are good. Everything before the covariance decay sentence needs to go or be rewritten.

## Introduction: restructure and simplify

The introduction needs a clear five-paragraph flow. Paragraph 1 should establish that allocation of talent affects aggregate output, introduce the formula, and note that the correlation matters for executive pay (possibly as a footnote). Paragraph 2 should pivot squarely to executive mobility studies, dropping the executive pay models comparison. Paragraph 3 should explain why existing methods (KSS / citation 22) fall short: they restrict to a well-connected subsample that is unrepresentative of the full firm population. Paragraph 4 should introduce the new method, explaining that it estimates variance-covariance parameters rather than individual effects. Paragraph 5 should walk through identification step by step.

Existing paragraphs are too indirect and pile up jargon. Sentences like "Sparse mobility makes this a measurement problem" and "Short careers and few executive changes leave individual, firm and executive effects imprecisely estimated" are written to sound smart rather than to communicate.

> "I don't quite like the sentences. It's still too indirect for me. Like the next sentence is almost correct. 'Short careers and few executive changes leave individual, firm and executive effects imprecisely estimated.' It's a true statement. But no sane person would say this. Say what the fuck we mean. Don't cloud things."

> "What do you mean? Like leave imprecisely estimated. I think we mean that because executive careers are short and executive changes are few, we can only estimate individual, firm and executive effects imprecisely. Always be active when you can."

## Identification walkthrough: explain step by step

The identifying comparison should be explained in plain language using a concrete example, not with undefined nouns like "chains" and "links." Start with two managers at the same firm: manager 2 replaces manager 1 at firm j, and the change in performance reveals their relative talent. Then extend: manager 2 moves to another firm, giving an independent observation about their talent. Comparing the two distinct firms with two distinct managers, if there is positive sorting (good managers go to good firms), the outcomes will be similar because correlation is transitive.

> "Imagine manager 2 replacing manager 1 at firm 1. And then the change in firm performance is informative about the relative talent of manager 2 to manager 1. Okay, this is a relatively uncontroversial statement."

> "Longer path with the same endpoint configuration reveal how quickly it decays. Kind of true, but like endpoint configuration. What the fuck are you talking about? Nobody will understand what we just want to say."

## GMRF sentence: rewrite for clarity

The Gaussian Markov random field description should read: "We model the correlation of executive talent and firm productivity with a Gaussian Markov random field, an analog of an AR1 process on the graph of executive mobility across firms." Citation 27 belongs at "GMRF," not at the end of the sentence. The Markov assumption should be stated in plain language: for an executive, conditional on the firms they worked at, their talent is independent of more distant firm productivities, and vice versa for a firm.

## Say What You Mean: writing principles

The session identified a consistent set of writing principles for the paper:

- Write for an intelligent physicist who knows nothing about economics.
- Always prefer active voice.
- Introduce more steps than feel necessary; never skip the intermediate thought.
- Do not invent technical terms for things that can be said plainly. When terminology is necessary, define it once and use it consistently.
- One idea per sentence. Trailing "which/where/when" clauses usually signal a second idea that needs its own sentence.
- Explain the complication only after the reader has internalized the base case.
- Do not say what you do not do; say what you do.

> "Always be more active than you would want to be. Take it step by step. Always introduce more steps than you think you need, but don't try to sound smart. Don't make up technical terms that can be explained with simple words."

> "Allocation, sorting, mobility -- they mean almost the same thing. And I'm not sure we need all of these words."

## Citation checks

Several citations need verification: citations 14, 15, 21, 25 should be checked for correct placement. AKM (citation 1) belongs at the "noisy executive effects" point, not at the GMRF. Citation 12 (Greg Clark) needs the classical genetics reference he cites to also be included. The Tervio paper should be reread to check whether it assumes imperfect sorting before finalizing that sentence.

## Next steps

- Rewrite the abstract's first three sentences with plain language; keep the covariance decay sentence and the two empirical findings.
- Restructure introduction paragraphs: move executive pay models to a footnote in paragraph 1, make paragraph 2 squarely about mobility studies, add step-by-step identification walkthrough.
- Verify all citations and add Greg Clark's classical genetics reference.
- Formalize the "Say What You Mean" writing principles into up to eight bullet points, three sentences each, and merge with existing writing and editing skills later.