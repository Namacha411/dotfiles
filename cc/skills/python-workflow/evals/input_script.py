# /// script
# dependencies = [
#   "requests>=2.28.0",
# ]
# requires-python = ">=3.12"
# ///

"""GitHub ユーザーのリポジトリ一覧を取得して表示する。"""

import requests


def fetch_repos(username: str) -> list[dict]:
    """指定ユーザーのリポジトリ一覧を取得する。"""
    url = f"https://api.github.com/users/{username}/repos"
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    return response.json()


def main() -> None:
    repos = fetch_repos("torvalds")
    for repo in repos:
        print(repo["name"], "-", repo.get("description", ""))


if __name__ == "__main__":
    main()
