---
name: pr
description: Create a pull request — commit staged changes, push, and open a PR via gh.
model: haiku
---

# Create PR Skill

1. Use the **commit skill** to stage files and create a commit (it handles file confirmation, Haiku-generated Conventional Commits message, and Co-Authored-By).
2. Run `git branch --show-current` to confirm the current branch.
3. Push to the current branch: `git push -u origin <branch>`.
4. Create a PR using `gh pr create` with a descriptive title and body summarising the changes.
