# /// script
# dependencies = [
#   "requests>=2.28.0",
#   "rich>=13.0",
# ]
# requires-python = ">=3.12"
# ///

"""GitHub ユーザーのリポジトリ一覧を取得して表示する。"""

from typing import Any

import requests
from rich.console import Console
from rich.table import Table


def fetch_repos(username: str) -> list[dict[str, Any]]:
    """指定ユーザーのリポジトリ一覧を取得する。"""
    url = f"https://api.github.com/users/{username}/repos"
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    return response.json()


def main() -> None:
    console = Console()
    repos = fetch_repos("torvalds")

    table = Table(title="GitHub Repositories")
    table.add_column("Repository Name", style="cyan")
    table.add_column("Description", style="magenta")

    for repo in repos:
        name = repo["name"]
        description = repo.get("description", "")
        table.add_row(name, description or "[dim]No description[/dim]")

    console.print(table)


if __name__ == "__main__":
    main()
