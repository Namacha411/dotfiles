## Workflow

Investigate [issue/topic], create a brief plan, then implement it fully. Don't stop at the plan—proceed to code changes, run tests, and commit.

## Git Workflow

Before making any git operations, always:
1) Run 'git status' and 'git branch' to confirm the current branch and all modified/untracked files.
2) If not on the correct feature branch, switch or create it.
3) Stage ALL modified and new files—list them explicitly and ask me to confirm if any look unrelated.
4) After committing, run 'git diff HEAD~1 --stat' to verify the commit contains exactly what was intended.

## Python Workflow

### Python Script Execution Policy

When creating and running Python scripts, always use PEP 723 inline script metadata format:

1. Always include inline metadata at the top of Python scripts:
```python
   # /// script
   # dependencies = [
   #   "package-name>=version",
   # ]
   # requires-python = ">=3.14"
   # ///
```

2. Execution method: Use `uv run script.py` to execute Python scripts
   - This automatically handles dependency installation in an isolated environment
   - No need to manually create virtual environments or install packages

3. Best practices:
   - Explicitly declare all external dependencies in the `dependencies` array
   - Specify Python version requirements when needed
   - Use this format even for simple scripts to maintain consistency

4. Example:
```python
   # /// script
   # dependencies = [
   #   "requests>=2.28.0",
   # ]
   # ///
   
   import requests
   # script code here
```

This approach ensures reproducible, self-contained Python scripts that work across different environments.

### Python Type Hints Policy

Always use type hints when writing Python scripts:

1. Function signatures: Add type hints to all function parameters and return values
```python
   def process_data(items: list[str], threshold: int = 10) -> dict[str, int]:
       # function body
       return result
```

2. Modern syntax: Use Python 3.9+ union syntax
   - Use `list[str]` instead of `List[str]`
   - Use `dict[str, int]` instead of `Dict[str, int]`
   - Use `X | None` instead of `Optional[X]`
   - Use `X | Y` instead of `Union[X, Y]`

3. Import from typing when needed:
```python
   from typing import Any, Callable, TypeVar, Protocol
   from collections.abc import Iterator, Sequence
```

4. Complex types: Use TypeAlias for readability
```python
   UserId = int
   UserData = dict[str, Any]
```

This improves code readability, catches errors early, and enables better IDE support.
