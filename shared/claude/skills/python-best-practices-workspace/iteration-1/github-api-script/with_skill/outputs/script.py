# /// script
# dependencies = [
#   "httpx>=0.24.0",
# ]
# requires-python = ">=3.10"
# ///

"""GitHub API からスター数上位10リポジトリを取得して表示するスクリプト。"""

from typing import Any, Final

import httpx


GITHUB_API_BASE: Final = "https://api.github.com"
SEARCH_ENDPOINT: Final = f"{GITHUB_API_BASE}/search/repositories"
REPOSITORIES_LIMIT: Final = 10
TIMEOUT_SECONDS: Final = 10


def fetch_top_repositories() -> list[dict[str, Any]]:
    """GitHub API からスター数上位10リポジトリを取得する。

    Returns:
        リポジトリ情報を含む辞書のリスト。各辞書には name, url, stargazers_count を含む。

    Raises:
        httpx.HTTPError: HTTP リクエストが失敗した場合
    """
    params = {
        "q": "stars:>1",
        "sort": "stars",
        "order": "desc",
        "per_page": REPOSITORIES_LIMIT,
    }

    with httpx.Client(timeout=TIMEOUT_SECONDS) as client:
        response = client.get(SEARCH_ENDPOINT, params=params)
        response.raise_for_status()
        data = response.json()

    assert isinstance(data, dict), "Expected response to be a dictionary"
    items = data.get("items", [])
    assert isinstance(items, list), "Expected 'items' to be a list"

    return items


def format_repository(repo: dict[str, Any]) -> str:
    """リポジトリ情報をフォーマットして表示用文字列を返す。

    Args:
        repo: リポジトリ情報を含む辞書

    Returns:
        フォーマット済みの表示用文字列
    """
    name = repo.get("full_name", "N/A")
    url = repo.get("html_url", "N/A")
    stars = repo.get("stargazers_count", 0)
    description = repo.get("description") or "説明なし"

    return f"{name} ({stars} stars)\n  {description}\n  {url}"


def main() -> None:
    """メイン処理。スター数上位10リポジトリを取得して表示する。"""
    print("GitHub API からスター数上位10リポジトリを取得中...\n")

    repositories = fetch_top_repositories()

    print(f"スター数上位 {len(repositories)} リポジトリ:\n")
    for i, repo in enumerate(repositories, start=1):
        print(f"{i}. {format_repository(repo)}\n")


if __name__ == "__main__":
    main()
