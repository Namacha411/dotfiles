---
name: commit
description: Git commit workflow — stage files, generate a Conventional Commits message via Claude Haiku, and commit. Use for any commit request.
model: haiku
---

# Commit Skill

Creates a git commit by having Claude Haiku analyze the diff and recent history, then generates a Conventional Commits message (subject + optional body) — keeping API costs low while maintaining good commit hygiene.

## Workflow

### 1. Gather context

Run these in parallel:

```bash
git status
git diff HEAD
git log --oneline -10
```

If the working tree is completely clean with nothing to stage or commit, tell the user and stop.

### 2. Show files and ask for confirmation

List every modified, staged, and untracked file. Ask the user to confirm which files to include (default: all). Flag any files that look unrelated to the current task — the user should make the final call. Wait for confirmation before proceeding.

### 3. Stage the confirmed files

Run `git add` with each confirmed filename listed explicitly. Avoid `git add .` or `git add -A` to prevent accidentally staging sensitive files like `.env`.

### 4. Generate the commit message

Collect the staged diff:

```bash
git diff --staged
```

Using the diff and recent git log (from step 1), generate a Conventional Commits message following these rules:

- type: feat | fix | docs | style | refactor | perf | test | chore | ci | build
- scope: optional — the module or area affected (e.g., nvim, powershell, cc)
- description: imperative mood, lowercase, no trailing period, 72 chars max for the entire subject line
- body: include when the change benefits from explanation of *why* (not just what). Wrap at 72 chars per line. Omit for trivial or self-explanatory changes.
- Breaking changes: add ! before the colon (e.g., feat!: drop Node 14 support)

Use the recent commit history as a style reference — match the tone, scope naming, and level of detail already established.

### 5. Show the message and confirm

Present the generated message to the user. Let them accept it as-is or provide edits — if they change anything, use their version verbatim.

### 6. Commit

```bash
git commit -m "$(cat <<'EOF'
<subject line>

<body if present>

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
EOF
)"
```

### 7. Verify

Run `git diff HEAD~1 --stat` and show the result so the user can confirm the commit contains exactly what was intended.
