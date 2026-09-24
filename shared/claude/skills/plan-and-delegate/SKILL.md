---
name: plan-and-delegate
description: >
  Splits work into shards and delegates them to haiku/sonnet/opus subagents, keeping the
  orchestrator's context small. Use when work has 3+ independent shards, exploration or logs
  that would flood the main context, the same change repeated across files, or when the user
  asks to delegate, parallelize, or save context. Skip for small edits already in context.
---

# Plan and Delegate

Use this workflow to keep the orchestrator's context small while delegating token-heavy implementation, exploration, and verification work to cheaper Claude Code subagents.

The orchestrator keeps ownership of intent, design, task decomposition, integration, verification strategy, and final decisions. Workers perform bounded, self-contained work from explicit specs.

## Activation gate

Use this workflow only if at least one condition is true:

- The task has 3+ independent implementation shards.
- Exploration, logs, generated diffs, or repeated edits would materially pollute the main context.
- The same implementation pattern repeats across files or modules.
- The task benefits from parallelism or worktree isolation.
- The user explicitly asks to delegate, parallelize, save context, or reduce cost.

Do not use it for one-shot fixes, tiny edits, or tasks where writing a full worker spec costs about as much as doing the work directly.

## Core principle

Expensive context should stay thin. Token-heavy work should be pushed into fresh, bounded worker contexts.

- **Orchestrator**: investigate enough to decide, plan, split tasks, write specs, choose models, verify, integrate, document decisions.
- **Workers**: perform bounded exploration, implementation, test execution, log summarization, or fresh diff review.

Delegation is profitable when it reduces expensive-model context and keeps noisy work out of the main conversation. It is counterproductive when the delegation packet and review overhead exceed the task itself.

## Recursive delegation

Subagents can spawn sub-workers of their own, up to three layers below the main conversation (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`; at the limit the `Agent` tool is withheld). A worker only delegates if its tool list includes `Agent` — the built-in Explore and Plan agents do not. To keep a worker such as a read-only reviewer from spawning, omit `Agent` from its `tools` or add it to `disallowedTools`.

Use recursion only when a worker genuinely benefits from parallelizing its own sub-tasks. Avoid recursive delegation for simple or sequential work — each additional layer adds startup and summary overhead.

Recursive workers must still write self-contained specs for their own sub-workers. The orchestrator owns the overall plan and final verification; recursive workers are responsible only for their own shard and its direct outputs.

## Fresh-context assumption

Workers start in a fresh isolated context: they do not inherit the main conversation history, prior reasoning, or previously read files.

However, custom subagents may receive normal project context such as `CLAUDE.md`, memory, git status, environment information, and preloaded skills. Therefore, every delegated task must still restate the target files, constraints, expected behavior, tests, and report format.

## Worker types

Use these archetypes. Prefer project-local agents under `.claude/agents/` when available; otherwise map read-only archetypes to the built-in `Explore` agent and the rest to `general-purpose` with a per-invocation `model`.

| Worker | Model | Tools | Use |
|---|---:|---|---|
| cheap-researcher | haiku | Read, Grep, Glob, Bash | broad read-only exploration, dependency tracing, log summarization |
| cheap-test-runner | haiku | Read, Grep, Glob, Bash | targeted tests, lint, typecheck, failure summary |
| cheap-implementer | haiku or sonnet | Read, Grep, Glob, Edit, Write, Bash | bounded implementation shard |
| senior-implementer | opus | Read, Grep, Glob, Edit, Write, Bash | high-stakes implementation with architecture-level judgment or security sensitivity |
| cheap-diff-reviewer | haiku or sonnet | Read, Grep, Glob, Bash | fresh review of final diff against acceptance criteria |

Use read-only workers whenever possible. Implementation workers should use worktree isolation for risky or parallel edits.

## Model selection

Start with the cheapest model that can plausibly succeed.

| Task type | Default model |
|---|---:|
| Mechanical scaffolding, boilerplate, precise RED-test-driven implementation, repeated changes, shallow exploration | haiku |
| Bounded implementation with non-trivial logic or local ambiguity | sonnet |
| High-stakes work with architecture-level judgment, security sensitivity, or where errors are very costly | opus |
| Architecture, cross-cutting integration, final judgment | orchestrator's own model (not delegated) |

Escalation rule:

1. If Haiku fails because the spec was incomplete, rewrite the spec and retry once.
2. If Haiku fails because the task needs reasoning, integration judgment, or ambiguity resolution, escalate to Sonnet.
3. Reserve Opus for high-stakes shards where errors are expensive; do not use it as a default escalation path.
4. Do not blindly retry the same weak spec.

**Cost note:** Always prefer abstract model names (`haiku`, `sonnet`, `opus`, `fable`) over pinned model IDs such as `claude-haiku-4-5-20251001`. Abstract names automatically route to the current-generation model at each tier, preventing accidental use of stale or more expensive pinned versions and enabling automatic cost optimization as the model lineup evolves. `fable` is an assignable worker model like the others — it is not reserved for the orchestrator.

For predictable cost, prefer setting `model` in subagent frontmatter. Use per-invocation model overrides only when a shard clearly needs escalation.

## Communication language

Use English for worker-facing prompts and reports when possible, regardless of the user's language.

Use the user's language for final user-facing explanations.

Boundary:

- User-facing explanation: user's language.
- Worker-facing specification: English.
- Worker report: preferably English, concise, structured.

## Workflow

### 0. Optional go/no-go experiment

If the plan depends on an uncertain premise, run a cheap spike before full implementation.

Examples:

- Verify whether an API exists.
- Confirm a benchmark harness works.
- Check whether a migration or codemod approach is feasible.
- Run a minimal reproduction.

Skip this phase when the premise is obvious.

### 1. Explore and plan

The orchestrator should understand enough to make design decisions, but should avoid loading large files, logs, or broad search results into main context.

Use cheap read-only workers for broad exploration:

- Identify relevant files and symbols.
- Trace dependencies.
- Summarize large logs.
- Extract existing patterns.

The orchestrator then produces a dependency-aware implementation plan.

### 2. Split into shards

Each shard should be independently specifiable and verifiable.

Good shard size:

- One module plus tests.
- One API surface plus tests.
- One mechanical transformation across a bounded file set.
- One vertical slice with explicit acceptance criteria.

Avoid shards that require global design judgment or cross-cutting integration decisions.

If no task breakdown exists yet, produce one with `planning-and-task-breakdown` first, then turn its tasks into shards here.

### 3. Write delegation packets

Every worker must receive a self-contained English specification.

Include:

- Objective.
- Model.
- Isolation mode.
- Allowed files.
- Forbidden files.
- Existing APIs or patterns to reuse.
- Required changes.
- Tests to add or update.
- Verification commands.
- Non-goals.
- Report format.

Use `worker-prompt-template.md` for the canonical packet format.

### 4. Delegate in dependency batches

Run independent shards in parallel when possible.

Respect dependency order:

1. Foundation changes.
2. Dependent implementations.
3. Tests and integration wiring.
4. Final review and verification.

Do not start dependent shards until prior batch outputs are verified or at least stable enough to build on.

### 5. Verify deterministically

Do not trust worker self-reports.

Prefer deterministic gates:

- Targeted tests.
- Typecheck.
- Lint.
- Build.
- Snapshot or golden-file diffs.
- Migration dry-runs.
- UI screenshot or visual checks when relevant.

A worker or verification subagent may run targeted checks, but the orchestrator must confirm the important evidence before integration is considered complete.

At minimum, review:

- Commands run.
- Exit status.
- Relevant output excerpts.
- Changed files.
- Deviations from spec.
- Skipped checks.

### 6. Fresh diff review

Before final completion, ask a fresh read-only reviewer to inspect the final diff against the plan and acceptance criteria.

The reviewer should check only:

- Missing requirements.
- Missing tests.
- Edge cases.
- Security, data-loss, or concurrency risks.
- Out-of-scope file changes.
- Regressions likely from the diff.

Ignore style nits unless they cause correctness or maintainability risk.

This overlaps with `doubt-driven-development`'s adversarial-review posture. When that skill is loaded, use its review discipline for this step instead of duplicating it here; treat this step as its integration point for delegated work.

### 7. Integrate and finish

The orchestrator owns final integration.

Responsibilities:

- Resolve conflicts or overlapping edits.
- Perform cross-shard wiring.
- Update documentation or ADRs when necessary.
- Run final verification.
- Produce the final user-facing summary.

Final response should include:

- What changed.
- Verification commands and results.
- Remaining risks or skipped checks.
- Any decisions made by the orchestrator.

## Safety and permissions

- Read-only workers must not have Edit or Write tools.
- Implementation workers should use `isolation: worktree` when edits are risky or parallel.
- Test runners may use Bash, but should use repo-defined test/lint/typecheck/build commands.
- Avoid destructive commands.
- Never use `bypassPermissions` for cheap workers unless the repository is disposable.
- Do not delegate secrets handling, credential changes, production deploys, or destructive migrations to cheap workers.

## Anti-patterns

The failures that the sections above don't already cover:

- Delegating vague requests such as "improve the code".
- Delegating architecture or trade-off decisions.

## Operational notes

- Use the todo list to track shards, dependencies, assigned worker, model, and verification state.
- Continue the same worker only when its local context is useful; otherwise start a fresh worker with a better spec.
- Keep worker reports concise.
- Treat worker output as untrusted until verified.
- Keep large templates, examples, and case studies outside this file to preserve skill loading efficiency.

