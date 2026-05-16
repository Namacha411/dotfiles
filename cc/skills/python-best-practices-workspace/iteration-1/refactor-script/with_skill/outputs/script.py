# /// script
# dependencies = [
#   "requests>=2.28.0",
# ]
# requires-python = ">=3.12"
# ///

"""GitHub API から JSON データを取得して表示する。"""

from typing import Any

import requests


def get_data(url: str, timeout: int = 30) -> dict[str, Any]:
    """指定 URL から JSON データを取得する。

    Args:
        url: リクエスト先 URL
        timeout: タイムアウト秒数（デフォルト: 30）

    Returns:
        レスポンス JSON をパースした辞書

    Raises:
        requests.RequestException: リクエスト失敗時
    """
    response = requests.get(url, timeout=timeout)
    response.raise_for_status()
    return response.json()


def main() -> None:
    """メイン処理。GitHub API データを取得して表示する。"""
    data = get_data("https://api.github.com")
    print(data)


if __name__ == "__main__":
    main()
