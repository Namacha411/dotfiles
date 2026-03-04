# Create PR Skill
1. Run `git status` and show ALL changed files
2. Ask user to confirm which files to include (default: all)
3. Run `git branch --show-current` to confirm target branch
4. Stage confirmed files, commit with conventional commit message
5. Push to the current branch
6. Create PR using `gh pr create` with a descriptive title and body
