# Plan and Delegate Examples

This file contains examples and case studies for the `plan-and-delegate` skill.

## Example 1: Pure functions with precise RED tests

### Situation

A repository needs three small utility functions implemented in one module:

- `l2_cache_bytes()`
- `num_threads()`
- `adaptive_block_bounds(n, nnz, l2, threads) -> (usize, usize)`

The behavior can be specified with exact signatures and tests.

### Decision

Delegate to a Haiku implementation worker.

Why:

- The work is bounded to one module plus tests.
- The behavior can be pinned down by RED tests.
- The implementation is mostly mechanical once the tests are known.
- The orchestrator does not need to load the full surrounding code into main context.

### Worker packet

```text
You are implementing cache/thread utility functions in the Rust module `src/machine.rs`.

Objective:
- Implement three utility functions with deterministic tests.

Model:
- haiku

Isolation:
- worktree

Allowed files:
- src/machine.rs
- tests/machine_tests.rs

Forbidden files:
- Cargo.toml
- Cargo.lock
- benches/
- generated artifacts

Existing APIs / patterns to reuse:
- Read neighbouring functions in `src/machine.rs` first.
- Match existing error handling and naming style.

Required changes:
1. Implement `l2_cache_bytes() -> usize`.
2. Implement `num_threads() -> usize`.
3. Implement `adaptive_block_bounds(n: usize, nnz: usize, l2: usize, threads: usize) -> (usize, usize)`.

Tests to add or update:
- Add tests for default/fallback behavior.
- Add tests for small inputs.
- Add tests for large sparse inputs.

Expected RED state:
- Tests should fail before implementation because functions are missing or stubbed.

Verification commands:
- cargo test machine_tests
- cargo clippy --all-targets -- -D warnings

Constraints:
- Add no new dependencies.
- Avoid unrelated refactors.
- Do not change public APIs beyond the requested functions.

Report format:
- Files changed.
- RED failure observed? yes/no, with short reason.
- Final commands and exit status.
- Deviations from spec.
- Remaining risks.
```

### Orchestrator verification

After the worker reports success, the orchestrator should run or confirm:

```bash
cargo test machine_tests
cargo clippy --all-targets -- -D warnings
```

If these pass, the shard can be integrated into the next batch.

## Example 2: Broad codebase exploration before planning

### Situation

The user asks to replace a deprecated API across the repository, but the relevant call sites are unknown.

### Decision

Delegate exploration to a read-only Haiku worker before planning edits.

Why:

- The search may touch many files.
- Loading all call sites into main context would be noisy.
- The output needed by the orchestrator is only a list of files, patterns, and risks.

### Worker packet

```text
You are a read-only research worker.

Objective:
- Find all usages of the deprecated API `LegacyClient.fetchData` and summarize replacement patterns.

Rules:
- Do not edit files.
- Prefer Grep/Glob before reading large files.
- Do not paste large file contents.
- Summarize only what is needed for implementation planning.

Search targets:
- `LegacyClient.fetchData`
- `fetchData(`
- `LegacyClient`
- src/
- tests/

Questions to answer:
1. Which files call `LegacyClient.fetchData`?
2. Are there existing usages of the replacement API `DataClient.fetch`?
3. Are any call sites in generated, vendored, or migration files?
4. Which call sites can be changed mechanically?
5. Which call sites need local reasoning?

Report format:
- Relevant files and symbols.
- Existing replacement patterns.
- Recommended shard boundary.
- Risks/unknowns.
```

### Expected worker output shape

```text
Relevant files and symbols:
- src/api/foo.ts: `loadFoo` calls `LegacyClient.fetchData`.
- src/api/bar.ts: `loadBar` calls `LegacyClient.fetchData`.
- tests/api/foo.test.ts: mocks old response shape.

Existing replacement patterns:
- src/api/baz.ts uses `DataClient.fetch({ key, signal })`.

Recommended shard boundary:
- Shard A: foo path + tests.
- Shard B: bar path + tests.
- Shard C: shared mock helpers.

Risks/unknowns:
- bar path transforms error codes differently; likely needs Sonnet.
```

## Example 3: Mechanical repeated refactor

### Situation

The repository has many files using `OldButton` that should be replaced by `Button` with a renamed prop.

### Decision

Use a cheap researcher to locate patterns, then one or more Haiku implementation workers for mechanical batches.

Why:

- The same transformation repeats.
- The fixed delegation overhead is amortized across many files.
- The orchestrator should avoid reading every changed file in full.

### Batch plan

```text
Batch 1: read-only exploration
- Find all OldButton imports and prop usages.
- Identify files with non-mechanical cases.

Batch 2: mechanical changes
- Worker A: src/pages/**
- Worker B: src/components/**

Batch 3: verification
- Run targeted component tests.
- Run typecheck.
- Fresh diff review.
```

### Implementation packet

```text
You are performing a mechanical UI refactor.

Objective:
- Replace `OldButton` with `Button` and rename prop `kind` to `variant` in the assigned files.

Model:
- haiku

Isolation:
- worktree

Allowed files:
- src/components/**/*.tsx

Forbidden files:
- src/pages/**
- generated/**
- package.json
- lockfiles

Existing APIs / patterns to reuse:
- `Button` is exported from `src/ui/Button`.
- Existing usage examples are in `src/components/Header.tsx`.

Required changes:
1. Replace imports from `src/ui/OldButton` with `src/ui/Button`.
2. Replace JSX tag `OldButton` with `Button`.
3. Rename prop `kind` to `variant`.
4. Preserve children and other props unchanged.

Tests to add or update:
- Do not add tests unless an existing snapshot requires update.

Verification commands:
- pnpm typecheck
- pnpm test -- --runInBand src/components

Constraints:
- No unrelated formatting.
- Do not change behavior.
- Do not touch files outside the allowed glob.

Report format:
- Files changed.
- Commands run with exit status.
- Any non-mechanical cases skipped.
- Remaining risks.
```

## Example 4: When not to delegate

### Situation

A one-line bug fix is needed in a function the orchestrator has already read.

### Decision

Do not delegate.

Why:

- The orchestrator already has the relevant context.
- Writing a delegation packet would cost more than making the edit.
- Parallelism and context isolation provide no benefit.

### Correct action

The orchestrator should edit directly, run the targeted test, and summarize the result.

## Example 5: Haiku failure and escalation

### Situation

A Haiku worker implemented a shard but misunderstood a subtle compatibility requirement.

### Decision

Do not keep retrying the same prompt.

First classify the failure:

- If the spec omitted necessary context, rewrite the spec and retry once with Haiku.
- If the task required local reasoning or compatibility judgment, escalate to Sonnet.

### Escalation packet

```text
This is a retry with an improved specification.

Previous failure summary:
- The prior implementation changed the public error code from `NOT_FOUND` to `MISSING`, breaking compatibility.

Why the previous spec was insufficient:
- It did not state that public error codes are part of the API contract.

Updated objective:
- Preserve all public error codes while migrating the internal client call.

Additional context:
- `NOT_FOUND`, `UNAUTHORIZED`, and `RATE_LIMITED` are public API values.
- Internal errors from `DataClient.fetch` must be mapped to the old values.

Allowed files:
- src/api/bar.ts
- tests/api/bar.test.ts

Verification commands:
- pnpm test tests/api/bar.test.ts
- pnpm typecheck

Do not repeat the previous approach if it changes public error values.
```

## Example 6: Verification-only worker

### Situation

A worker generated a large diff and produced a long test log. The orchestrator wants evidence without loading the entire log into main context.

### Decision

Delegate log summarization and targeted checks to a read-only Haiku test runner.

### Worker packet

```text
You are a verification worker.

Objective:
- Run targeted verification for the current diff and summarize only pass/fail evidence.

Rules:
- Do not edit files.
- Do not paste full logs.
- Stop after the first failing command unless a later command is still useful for diagnosis.

Verification commands:
1. pnpm test tests/api/bar.test.ts
2. pnpm typecheck
3. pnpm lint src/api/bar.ts

Report format:
- Command.
- Exit status.
- Relevant output excerpt, max 30 lines.
- Likely cause if failed.
- Suggested next action.
```

## Case study: effective delegation

A multi-module implementation was split into two dependency-aware batches and delegated to cheaper workers.

Observed effect:

- Roughly 105k tokens of exploration, implementation, and editing stayed inside worker contexts.
- The orchestrator context remained small, around 7% of the available window.
- The orchestrator retained design and integration decisions.
- Cheap workers handled the token-heavy implementation loops.

Why it worked:

- Each shard had precise file boundaries.
- Tests and verification commands were explicit.
- Independent shards ran in batches.
- Worker reports were concise.
- The orchestrator re-verified important results.

## Case study: inefficient delegation

A task with only three tiny modules of a few dozen lines each was delegated.

Observed effect:

- Delegation packet overhead exceeded implementation savings.
- Worker startup and summary tokens added cost.
- Wall-clock time increased.

Lesson:

Delegation is not a goal. Use it when it preserves expensive context, amortizes repeated work, or enables useful parallelism.

## Checklist before delegating

Ask:

1. Can I write a self-contained spec?
2. Are target files and forbidden files clear?
3. Are tests or verification commands known?
4. Is this large, repetitive, exploratory, or parallelizable enough to justify overhead?
5. Can the worker report concisely without pasting large diffs?
6. Is the model choice explicit?
7. Is worktree isolation needed?
8. What evidence will I require before trusting the result?

If the answer to 1 or 3 is no, improve the plan before delegating.

If the answer to 4 is no, do the work directly.
