---
type: testing
title: Agent Eval Harness
description: Documents the Python-based evaluation framework in eval/ that tests a code-reading AI agent's ability to answer factual questions about Stata do files used in the CEO value placebo-controlled event study project.
tags: [testing, evaluation, agent, opencode, Stata, CLI]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T19:57:00.087Z
sources:
  - id: openwiki-source-206a0ed9f411afc413e19384
    resource: repo://eval/__main__.py
  - id: openwiki-source-5b76df64093f7d0f7683af4c
    resource: repo://eval/ceo_overlap.yaml
  - id: openwiki-source-bac199b4d43889d526c7111b
    resource: repo://eval/ceo_overlap/filter.do
  - id: openwiki-source-68d11b5da871f0c25bdfd23d
    resource: repo://eval/ceo_overlap/intervals.do
  - id: openwiki-source-0865bf81e91731522dc10289
    resource: repo://eval/filter_restrictions.yaml
  - id: openwiki-source-9de89a76eafa0cb0a1fd0ee4
    resource: repo://eval/filter_restrictions/filter.do
  - id: openwiki-source-97e472655129fcaac417a9d2
    resource: repo://eval/placebo_controls.yaml
  - id: openwiki-source-665004bcac8495c26e67ec81
    resource: repo://eval/placebo_controls/event_study_sample.do
  - id: openwiki-source-20b7023d0fd49e82659efe62
    resource: repo://eval/questions.py
  - id: openwiki-source-ab1b36946c5fe7ce7eb8a42f
    resource: repo://eval/runner.py
  - id: openwiki-source-4bf85bde7a0238870007874e
    resource: repo://eval/schemas.py
  - id: openwiki-source-e013c33e38fb24d71b8c0bf3
    resource: repo://eval/server.py
generated: { by: "openwiki/0.5.0", at: "2026-09-06T19:57:00.087Z" }
---

# Agent Eval Harness

## Purpose

The eval harness (`eval/`) is an automated testing framework that evaluates an AI agent's ability to read, search, and answer questions about the project's Stata `.do` files. It does not test correctness of the research pipeline itself; it tests whether an agent equipped with file-reading tools can accurately extract facts from the source code. The harness exercises the same agent infrastructure (`opencode`) used by human developers, but in a headless, scriptable mode.

## Architecture Overview

The harness lives entirely under `eval/` and consists of five Python modules plus YAML test definitions:

| Path | Responsibility |
|------|---------------|
| `eval/__main__.py` | CLI entry point: parses `--model`, `--port`, `--concurrency`, `--results-dir` |
| `eval/schemas.py` | Pydantic data models: `Question`, `TestCase`, `ModelConfig`, `EvalConfig` |
| `eval/config.py` | Default configuration singleton (`DEFAULT_CONFIG`) |
| `eval/questions.py` | YAML discovery and case loading (`make_cases()`, `load_test_cases()`) |
| `eval/runner.py` | Core evaluation loop: launches servers, sends prompts, evaluates answers |
| `eval/server.py` | `OpenCodeServer` lifecycle manager: starts/stops headless `opencode serve`, sends prompts via `opencode run` |

### Relationship to the Project

<!-- openwiki: mermaid parse failed and this diagram was converted to a text fence so it does not break rendering. Fix the diagram source and restore the mermaid fence. Parser error: Heuristic: an unescaped angle bracket inside a label breaks rendering; rephrase the label. -->
```text
flowchart LR
    YAML["YAML Test Cases<br/>eval/*.yaml"] --> Q["questions.py<br/>load_test_cases"]
    Q --> R["runner.py<br/>evaluate_test_case"]
    R --> S["server.py<br/>OpenCodeServer"]
    S --> OC["opencode serve<br/>(headless)"]
    OC --> A["Agent under test<br/>(reads .do files)"]
    A --> R
    R --> REPORT["JSON report<br/>eval/results/"]
    DO_FILES["Stata .do files<br/>eval/{case_name}/*.do"] --- A
```

## Entry Points

### CLI

```sh
# Default (openai/gpt-5.4-mini, concurrency=1)
python -m eval

# Custom model, output directory, concurrent evaluations
python -m eval --model "anthropic/claude-sonnet-4-20250514" --results-dir /tmp/eval-results --concurrency 2

# Specify opencode server port (0 = auto)
python -m eval --port 8080
```

The CLI is defined in `/eval/__main__.py`. All optional flags override fields in `DEFAULT_CONFIG`.

### Programmatic

```python
from eval.runner import run_eval
from eval.schemas import EvalConfig

cfg = EvalConfig(model_id="openai/gpt-4o", concurrency=4)
run_eval(cfg)
```

## Data Models

Defined in `/eval/schemas.py` using Pydantic v2:

- **`Question`**: `id` (str), `type` ("true_false" or "numeric"), `prompt` (str), `answer` (bool or float), `rubric` (optional str explaining the expected source).
- **`TestCase`**: `name` (str), `description` (optional str), `questions` (list of `Question`).
- **`ModelConfig`**: `provider`, `model_id`, optional `base_url`, optional `api_key_env`.
- **`EvalConfig`**: `model_id` (default `openai/gpt-5.4-mini`), `results_dir` (default `eval/results`), `server_port` (default 0 = auto), `concurrency` (default 1).

## Test Case Definition (YAML)

Each test case has two parts:

1. **YAML file** at `eval/{case_name}.yaml` describing the questions.
2. **Subdirectory** at `eval/{case_name}/` containing the `.do` files the agent reads.

The YAML schema:

```yaml
name: <case_name>
description: "Human-readable description"
questions:
  - id: q1
    type: true_false        # or numeric
    prompt: "True/false question text"
    answer: true            # or false, or an integer for numeric
    rubric: "Source reference explaining the expected answer"
```

### Current Test Cases

| Test Case | Description | `.do` Files in Subdirectory | Questions |
|-----------|-------------|----------------------------|-----------|
| `ceo_overlap` | CEO overlap handling in `intervals.do` and `filter.do` | `intervals.do`, `filter.do` | q1: Whether >3-year overlap excludes entire firm (false — `local T 2` truncates, no firm exclusion). q2: Overlap threshold in years (2). |
| `filter_restrictions` | Sample restriction criteria in `filter.do` | `filter.do` | q1: Whether firms with >2 CEOs per year are dropped (true). q2: Maximum CEO spell count (12). |
| `placebo_controls` | Placebo-controlled event study sampling in `event_study_sample.do` | `event_study_sample.do` | q1: Whether 10:1 placebo-to-treated ratio is targeted (true). q2: Number of targeted placebo controls per treated (10). |

The `.do` files in each subdirectory are copies of the actual production scripts (e.g., `eval/ceo_overlap/intervals.do` is a copy of `lib/create/intervals.do`). Keeping them in isolated directories ensures the agent under test cannot access unrelated files and that the test is self-contained.

## Control Flow

### Discovery (`/eval/questions.py`)

```python
_discover_test_cases(eval_dir="eval") -> list[tuple[str, TestCase]]
```

1. Globs `eval/*.yaml` in sorted order.
2. For each YAML file, derives `name = yf.stem` and expects `eval/{name}/` to exist as a directory. Skips YAML files without a matching subdirectory.
3. Loads and validates YAML into a `TestCase` pydantic model.
4. `make_cases()` flattens all test cases into a list of dicts with keys: `name`, `testcase`, `question_id`, `type`, `prompt`, `truth`, `rubric`.

### Evaluation (`/eval/runner.py`)

`run_eval(cfg)`:

1. Calls `make_cases()` to get all flattened questions.
2. Groups questions by `testcase` name.
3. For each test case:
   - Starts a headless `opencode serve` process in `eval/{testcase_name}/`.
   - For each question in the test case:
     - Formats a prompt instructing the agent to search (`glob **/*.do`), read relevant files, then answer.
     - For `true_false`: prepends `"Start with \"TRUE/FALSE:\" followed by your answer."`.
     - For `numeric`: prepends `"Start with \"NUMERIC:\" followed by the numeric value."`.
     - Sends the prompt via `opencode run --attach <server_url>`.
     - Parses the response with regex to extract the answer.
     - For `true_false`: checks `TRUE/FALSE:` followed by `True|False` (case-insensitive). Falls back to line-start `TRUE|FALSE`.
     - For `numeric`: checks `NUMERIC:` followed by a signed integer.
     - Records `passed: bool` in the result.
4. Prints a per-test-case summary with pass/fail counts.
5. Saves a JSON report to `eval/results/results_{timestamp}.json`.

The prompt template used:

```
You are being evaluated on your ability to answer questions about Stata .do files in this research project.

Use your tools (glob **/*.do to start, then grep and read) to find the relevant code and answer.

FIRST search for and read the relevant files, THEN answer the question.

{question_text}

Provide a brief reasoning after your answer.
```

### Server Lifecycle (`/eval/server.py`)

`OpenCodeServer` manages an `opencode serve` subprocess per test case directory:

1. **`start()`**: Finds a free port (or uses the configured one), spawns `opencode serve --port <port>` with `cwd` set to the test case's `.do` directory, polls `/global/health` until the server responds 200 or a 30-second timeout elapses.
2. **`ask(prompt, model_id)`**: Runs `opencode run --attach <base_url> [--model <model_id>] <prompt>` and returns stdout. Times out after 600 seconds. Raises `RuntimeError` on non-zero exit.
3. **`stop()`**: Terminates the server process gracefully, kills on timeout.
4. Context manager support (`with OpenCodeServer(...) as server:`).

## Adding a New Test Case

1. **Create the `.do` file(s)**: Place one or more Stata `.do` files in `eval/{new_case_name}/`. These should be copies (or simplified excerpts) of the production scripts the agent must analyze.
2. **Define the YAML**: Create `eval/{new_case_name}.yaml` with the same name, containing the test case metadata and questions.
3. **Run it**: `python -m eval --model <model>` — the harness auto-discovers the new case through the glob pattern in `_discover_test_cases`.

The YAML file and subdirectory must share the same stem; otherwise the discovery logic silently skips the case.

## Test Results

Results are saved as JSON to `eval/results/results_{YYYYMMDD_HHMMSS}.json`. The report structure:

```json
{
  "model_id": "openai/gpt-4o",
  "timestamp": "20260401_120000",
  "results": [
    {
      "name": "ceo_overlap/q1",
      "type": "true_false",
      "question": "When a leaving and entering CEO overlap for 3 or more years...",
      "output": "TRUE/FALSE: false...",
      "passed": true,
      "expected": false
    }
  ],
  "failures": [],
  "summary": {
    "passed": 6,
    "total": 6,
    "pct": 100.0
  }
}
```

## Invariants and Failure Modes

- **Server startup failure**: If `opencode serve` does not respond to `/global/health` within 30 seconds, `RuntimeError` is raised and the test case is lost (no partial results saved for that case).
- **Missing test case directory**: If `eval/{case_name}/` does not exist, the case is skipped and recorded in the `failures` list.
- **Regex parse failure**: If the agent's output does not contain `TRUE/FALSE:` or `NUMERIC:` (or the fallback patterns), the question is marked as failed (`passed: false`).
- **`opencode run` non-zero exit**: Raises `RuntimeError`, aborting the test case.
- **`opencode run` timeout**: The 600-second subprocess timeout catches agents that loop indefinitely.
- **Results directory**: Created automatically if missing.

## Extension Points

- **Concurrency**: Controlled via `--concurrency` / `EvalConfig.concurrency`. Currently the harness processes test cases sequentially within each run; concurrency controls are reserved for future parallelization.
- **Model selection**: Any model ID supported by the `opencode` CLI (`--model`), including OpenRouter models (`openai/gpt-4o`, `anthropic/claude-sonnet-4-20250514`).
- **API providers**: Through `ModelConfig.provider` — supports `openai`, `openai_compatible` (for OpenRouter, Vercel AI Gateway, etc.), and `mock`.
- **Report format**: The JSON schema is straightforward; downstream aggregation scripts can read `eval/results/` across multiple runs.
