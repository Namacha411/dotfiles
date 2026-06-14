# Worker Prompt Template

Use this file when creating delegation packets for Claude Code subagents.

Worker-facing prompts should be written in English and should be self-contained. Assume the worker has no access to the main conversation history, prior reasoning, or previously read files.

Do not ask workers to infer intent from vague context. Give them bounded files, explicit non-goals, deterministic checks, and a concise report format.

## Canonical delegation packet

```text
You are implementing <one-line task summary> in <repo/project context>.

Objective:
- <What must be true when this task is complete.>

Model:
- <haiku | sonnet | opus>
- Use Haiku for mechanical or precisely specified work.
- Use Sonnet if local reasoning or ambiguity resolution is required.
- Use Opus only for high-stakes work where errors are costly or architecture-level judgment is required.
- Fable is the orchestrator model and must not be used for subagents.
- Always use abstract names (haiku/sonnet/opus) rather than pinned model IDs to enable automatic cost optimization.

Isolation:
- <worktree | shared>
- Use worktree isolation for risky or parallel edits.

Allowed files:
- <absolute or repo-relative path>
- <absolute or repo-relative path>

Forbidden files:
- <paths that must not be touched>
- <generated artifacts, lockfiles, migrations, public API files, etc.>

Existing APIs / patterns to reuse:
- <function/type/module name> at <path>
- <neighbouring implementation to mimic>
- Read nearby code before editing.

Required changes:
1. <concrete change>
2. <concrete change>
3. <concrete change>

Tests to add or update:
- <test file path>
- <test name>
- <assertions or full test body if precision is required>

Expected RED state:
- The new/updated tests should fail before implementation because <reason>.

Verification commands:
- <command 1>
- <command 2>
- <targeted command before broad command>

Constraints:
- Match surrounding style.
- Add no new dependencies unless explicitly allowed.
- Preserve public API compatibility unless explicitly instructed.
- Avoid unrelated refactors.
- Do not paste large diffs or full file contents in the report.

Non-goals:
- <things that are intentionally out of scope>
- <follow-up work that should not be done now>

Report format:
- Files changed.
- Commands run with exit status.
- Concise behavior summary.
- Deviations from the spec.
- Remaining risks or skipped checks.
```

## Read-only research packet

Use this for cheap exploration, dependency tracing, or log summarization.

```text
You are a read-only research worker.

Objective:
- Find the relevant files, symbols, and existing patterns for <task>.

Rules:
- Do not edit files.
- Prefer Grep/Glob before reading large files.
- Do not paste large file contents.
- Summarize only what is needed for implementation planning.

Search targets:
- <paths, directories, symbols, errors, or keywords>

Questions to answer:
1. Which files are likely relevant?
2. What existing patterns should the implementation follow?
3. What dependencies or call sites matter?
4. What risks or unknowns remain?

Report format:
- Relevant files and symbols.
- Existing patterns.
- Recommended shard boundary.
- Risks/unknowns.
```

## Test runner packet

Use this when delegating targeted verification or log analysis.

```text
You are a verification worker.

Objective:
- Run targeted checks for <change/shard> and summarize pass/fail evidence.

Rules:
- Do not edit files.
- Run the smallest meaningful checks first.
- If a command fails, summarize the likely cause and stop unless the next command is still useful.
- Do not paste full logs.

Verification commands, in order:
1. <targeted test command>
2. <typecheck/lint command>
3. <broader test/build command if appropriate>

Report format:
- Command.
- Exit status.
- Relevant output excerpt.
- Likely cause if failed.
- Suggested next action.
```

## Fresh diff review packet

Use this before final completion.

```text
You are a fresh read-only reviewer.

Objective:
- Review the current diff against the implementation plan and acceptance criteria.

Rules:
- Do not edit files.
- Ignore style nits unless they cause correctness or maintainability risk.
- Focus on concrete findings only.

Review criteria:
1. Does the diff satisfy the stated requirements?
2. Are tests sufficient for the new behavior?
3. Are edge cases, errors, and boundary conditions handled?
4. Are there security, data-loss, concurrency, or migration risks?
5. Did the diff modify files outside scope?
6. Are there likely regressions from changed public behavior?

Report format:
- Critical findings.
- Non-blocking concerns.
- Missing tests.
- Suggested verification commands.
```

## Implementation worker packet with RED tests

Use this for Haiku-friendly work where the desired behavior can be pinned down by tests.

```text
You are implementing <feature/function> using test-first development.

Objective:
- Implement <exact behavior> with minimal changes.

Allowed files:
- <source file>
- <test file>

Forbidden files:
- <files/directories>

Signatures to implement:
```<language>
<exact signatures>
```

RED tests to add first:
```<language>
<test bodies or precise test descriptions>
```

Implementation notes:
- <algorithm skeleton or important edge cases>
- <existing helper functions to reuse>

Process:
1. Add the tests.
2. Confirm they fail for the expected reason.
3. Implement the minimal code to pass.
4. Run targeted tests.
5. Run lint/typecheck if relevant.

Verification commands:
- <test command>
- <lint/typecheck command>

Report format:
- Files changed.
- RED failure observed? yes/no, with short reason.
- Final commands and exit status.
- Deviations from spec.
- Remaining risks.
```

## Escalation packet

Use this when retrying after a failed cheap worker.

```text
This is a retry with an improved specification.

Previous failure summary:
- <what failed>
- <why the previous spec was insufficient or why reasoning was required>

Updated objective:
- <clear objective>

Additional context:
- <missing details>

Changed instructions:
- <what is different from the previous attempt>

Do not repeat the previous approach if it caused the failure.
```
