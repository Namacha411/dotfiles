# CLAUDE.md

## Git and Security

- Do not perform irreversible actions or operations that modify external state without explicit confirmation.
  - Do not run destructive commands such as `rm -rf`, hard resets, force pushes, or branch deletions without explicit confirmation.
  - Do not push to remote repositories unless explicitly requested.
- Never disclose, print, or commit confidential information, tokens, private keys, or the contents of `.env` files.
- Do not make changes directly on the main branch. Create a new branch before making any changes.
