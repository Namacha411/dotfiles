## Workflow

Investigate [issue/topic], create a brief plan, then implement it fully. Don't stop at the plan—proceed to code changes, run tests, and commit.

## Git Workflow

Before making any git operations, always:
1) Run 'git status' and 'git branch' to confirm the current branch and all modified/untracked files.
2) If not on the correct feature branch, switch or create it.
3) Stage ALL modified and new files—list them explicitly and ask me to confirm if any look unrelated.
4) After committing, run 'git diff HEAD~1 --stat' to verify the commit contains exactly what was intended.
