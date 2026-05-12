---
name: python-workflow
description: >
  Python を書く際に適用するワークフロー。
  使い捨て単一スクリプトには uv + PEP 723、それ以外のプロジェクトには uv init + uv add で環境を構築し、
  型ヒントと PEP 8 スタイルで LSP 補完・静的型検査・コードの統一性を確保する。
  Python ファイルの新規作成、既存スクリプトの修正、依存パッケージの追加など、
  Python に関わる作業が発生したら必ずこのスキルを参照すること。
---

# Python Workflow

このスキルの目的は「未来の自分や他者がそのスクリプトを読んだとき、迷わず理解・修正できる」コードを書くことにある。
そのために uv で再現性を、型ヒントで静的解析可能性を、PEP 8 で一貫したスタイルを担保する。

---

## 1. 環境構築の選択

| ユースケース | 手法 |
|---|---|
| 使い捨て・単一ファイルのスクリプト | PEP 723 インラインメタデータ + `uv run` |
| 複数ファイル・継続開発・ライブラリ | `uv init` + `uv add` |

**迷ったら `uv init` を選ぶ。** PEP 723 は「このファイル 1 つで完結する、使い捨てのスクリプト」にのみ使う。

---

## 2. PEP 723 インラインメタデータ（使い捨て単一スクリプト）

スクリプトの先頭に以下のブロックを記述する。
これにより `uv run` が依存関係を自動解決し、仮想環境の手動管理が不要になる。

```python
# /// script
# dependencies = [
#   "requests>=2.28.0",
#   "rich>=13.0",
# ]
# requires-python = ">=3.12"
# ///
```

依存パッケージがない場合でも `dependencies = []` として残す（スキャフォールドとして機能する）。

### `if __name__ == "__main__":` ガード（必須）

**本体処理は必ず `if __name__ == "__main__":` で囲む。**

ty LSP は `uv python find --script <file>` で PEP 723 スクリプト用の venv Python パスを取得する。
このコマンドが機能するには、事前に `uv run --script <file>` で venv が作成されている必要がある。
`if __name__ == "__main__":` がないと、この venv 作成目的の `uv run` でスクリプトの副作用が走ってしまう。

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests",
# ]
# ///

import requests  # ← uv run 時はここまで実行（venv が作られる）

if __name__ == "__main__":  # ← 本体処理はここに書く
    resp = requests.get("https://example.com")
    print(resp.status_code)
```

初回 venv 作成（スクリプトを書いたら 1 回だけ実行）:

```bash
uv run --script foo.py   # インポートのみ走り即終了、venv が ~/.cache/uv 以下に作られる
```

その後 Neovim でファイルを開けば ty LSP が補完・型チェックを提供する。

### 実行方法

```bash
uv run script.py
```

- 仮想環境の作成・パッケージのインストールは `uv` が自動処理する
- `python script.py` は使わない（依存関係が解決されない恐れがある）
- 引数が必要な場合: `uv run script.py --arg value`

---

## 3. プロジェクト構築（uv init + uv add）

複数ファイル・継続開発・ライブラリなど、単一スクリプトに収まらない場合はプロジェクトとして管理する。

### セットアップ

```bash
uv init myproject
cd myproject
uv add requests rich        # 依存パッケージを追加
uv add --dev ruff ty        # 開発用ツールを追加
```

生成されるファイル:

```
myproject/
├── pyproject.toml   # プロジェクト設定・依存関係
├── .python-version  # Python バージョンのピン留め
├── uv.lock          # ロックファイル（git 管理する）
└── hello.py         # エントリポイント（任意に変更）
```

### 依存パッケージの管理

```bash
uv add httpx             # 依存パッケージを追加（pyproject.toml + uv.lock を更新）
uv remove requests       # 依存パッケージを削除
uv sync                  # uv.lock から venv を再現（git clone 後など）
```

### 実行方法

```bash
uv run python main.py       # スクリプトを実行
uv run python -m mypackage  # モジュールとして実行
uv run pytest               # テストを実行
```

---

## 4. 型ヒント（必須）

型ヒントにより LSP（ty など）の補完と静的型検査が有効になる。

### 基本ルール

```python
# 関数のシグネチャには必ず型ヒントを付ける
def process_items(items: list[str], limit: int = 10) -> dict[str, int]:
    ...

# None を返す場合も明示する
def setup() -> None:
    ...
```

### 型構文（Python 3.10+ 構文を使う）

| 避ける                    | 使う                    |
|--------------------------|------------------------|
| `Optional[X]`            | `X \| None`            |
| `Union[X, Y]`            | `X \| Y`               |
| `List[str]`              | `list[str]`            |
| `Dict[str, int]`         | `dict[str, int]`       |
| `Tuple[int, str]`        | `tuple[int, str]`      |

### typing モジュールのインポート

```python
from typing import Any, Callable, TypeVar, Protocol
from collections.abc import Iterator, Sequence, Generator
```

### 型の具体性

コレクション内の要素型まで明示する。`dict` や `list` で止めると静的解析の恩恵が薄れる。

```python
# 避ける: 内部型が不明
def get_users() -> list[dict]:          ...
def parse(data: dict) -> list[dict]:    ...

# 使う: 内部型まで具体的に
def get_users() -> list[dict[str, Any]]:          ...
def parse(data: dict[str, Any]) -> list[str]:     ...
```

### モジュール定数には `Final` を使う

モジュールレベルの定数は `Final` でアノテートすると、意図しない再代入を型チェッカーが検出できる。

```python
from typing import Any, Final

BASE_URL: Final = "https://api.example.com"
MAX_RETRIES: Final = 3
```

### 型エイリアス（複雑な型には名前をつける）

```python
UserId = int
Config = dict[str, Any]
```

---

## 5. PEP 8 スタイル

コードの見た目を統一することで、diff が意味のある変更だけを示すようになる。

### 命名規則

| 対象           | スタイル       | 例                     |
|---------------|---------------|------------------------|
| 変数・関数     | `snake_case`  | `user_name`, `get_data` |
| クラス         | `PascalCase`  | `DataProcessor`         |
| 定数           | `UPPER_SNAKE` | `MAX_RETRIES`           |
| モジュール     | `snake_case`  | `data_utils.py`         |
| プライベート   | `_leading`    | `_internal_state`       |

### インポート順序

標準ライブラリ → サードパーティ → ローカル の順に、グループ間は空行で区切る。

```python
import os
import sys
from pathlib import Path

import requests
from rich.console import Console

from my_module import helper
```

### スペースとレイアウト

- インデント: スペース 4 つ（タブ禁止）
- 最大行長: 88 文字（ruff/black のデフォルト）
- 演算子の周りにスペース: `x = a + b`（`x=a+b` は NG）
- コンマの後にスペース: `func(a, b, c)`

### ドキュメント文字列

公開関数・クラスには docstring を付ける。

```python
def fetch_data(url: str, timeout: int = 30) -> dict[str, Any]:
    """指定 URL から JSON データを取得する。

    Args:
        url: リクエスト先 URL
        timeout: タイムアウト秒数

    Returns:
        レスポンス JSON をパースした辞書

    Raises:
        requests.HTTPError: HTTP エラー時
    """
    ...
```

---

## 6. 完全なスクリプトテンプレート（PEP 723）

```python
# /// script
# dependencies = [
#   "requests>=2.28.0",
# ]
# requires-python = ">=3.12"
# ///

"""スクリプトの概要を一行で。"""

from typing import Any, Final

import requests


BASE_URL: Final = "https://api.example.com"
MAX_RETRIES: Final = 3


def fetch_data(url: str, timeout: int = 30) -> dict[str, Any]:
    """URL から JSON を取得して返す。"""
    assert timeout > 0, f"timeout must be positive, got {timeout}"
    response = requests.get(url, timeout=timeout)
    response.raise_for_status()
    return response.json()


def main() -> None:
    data = fetch_data(BASE_URL)
    print(data)


if __name__ == "__main__":
    main()
```

---

## 7. ruff による lint / format

ruff は PEP 8 チェック・自動フォーマット・import 整理を一括して行う。
プロジェクトに ruff をインストールせず `uvx` で都度実行できるため、スクリプト単体でも使いやすい。

### 実行コマンド

```bash
# lint（問題を検出）
uvx ruff check script.py

# lint + 自動修正
uvx ruff check --fix script.py

# フォーマット（black 互換、行長 88）
uvx ruff format script.py

# lint + format を一度に
uvx ruff check --fix script.py && uvx ruff format script.py
```

### 推奨設定（`pyproject.toml` があるプロジェクトの場合）

```toml
[tool.ruff]
line-length = 88

[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort (import order)
    "UP",  # pyupgrade (modern syntax)
]
```

スクリプト単体の場合は設定ファイル不要。デフォルトで PEP 8 準拠の lint が走る。

---

## 8. ty による型チェック

ty は Astral 製の Rust 実装型チェッカー。mypy / pyright より 10〜100x 高速で、`uvx` で都度実行できるためインストール不要。

### 実行コマンド

```bash
# ファイル単体をチェック（インストール不要）
uvx ty check script.py

# Python バージョンを指定
uvx ty check --python-version 3.12 script.py

# watch モード（ファイル変更を監視）
uvx ty check --watch script.py
```

### ty が検出する主なエラー

| エラー | 説明 |
|---|---|
| `invalid-argument-type` | 関数引数の型不一致 |
| `invalid-return-type` | 戻り値の型不一致 |
| `invalid-assignment` | 変数への代入時の型不一致 |

詳細は [`references/ty-reference.md`](references/ty-reference.md) を参照。

---

## 9. assert の使いどころ

**型で表現できるものは型で表現する。assert は型やコードだけでは読み取れない意味的な前提条件を補足するために使う。**

### assert を使う場面: 型システムが表現できないドメイン固有の制約

```python
# 型では表現できない次元制約
def matmul(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    assert a.shape[1] == b.shape[0], (
        f"Incompatible shapes for matmul: {a.shape} @ {b.shape} "
        f"(a.cols={a.shape[1]} != b.rows={b.shape[0]})"
    )
    return a @ b

# 確率値の制約（型は float だが意味的に 0〜1 に正規化されている前提）
def sample(weights: list[float]) -> int:
    assert abs(sum(weights) - 1.0) < 1e-9, f"weights must sum to 1.0, got {sum(weights)}"
    ...

# 引数間の依存関係
def paginate(offset: int, limit: int) -> list[str]:
    assert offset >= 0, f"offset must be non-negative, got {offset}"
    assert limit > 0, f"limit must be positive, got {limit}"
    ...
```

よく使う場面:
- 行列の次元整合性
- 確率値・正規化済みデータの範囲（0.0〜1.0 など）
- 2 つの引数の間の依存関係
- ソート済みや重複なしなど前処理の事後条件

### assert を使わない場面

- 型ヒントで表現できるもの（`int | None` で十分な nullable など）
- ユーザー入力のバリデーション → `ValueError` を raise する
- 本番で常に起きうるエラー（assert は `-O` フラグで無効化される）

---

## 参考ドキュメント

| ツール / 仕様     | URL |
|------------------|-----|
| uv               | https://docs.astral.sh/uv/ |
| PEP 723          | https://peps.python.org/pep-0723/ |
| ruff             | https://docs.astral.sh/ruff/ |
| ty               | https://docs.astral.sh/ty/ |
| PEP 8            | https://peps.python.org/pep-0008/ |
| typing モジュール | https://docs.python.org/3/library/typing.html |
| collections.abc  | https://docs.python.org/3/library/collections.abc.html |
| ty 詳細          | [references/ty-reference.md](references/ty-reference.md) |

---

## チェックリスト

### 使い捨て単一スクリプト（PEP 723）

- [ ] PEP 723 ヘッダーが先頭にある
- [ ] すべての依存パッケージが `dependencies` に列挙されている
- [ ] 本体処理を `if __name__ == "__main__":` で囲んでいる
- [ ] `uv run` で実行できることを確認した

### プロジェクト（uv init + uv add）

- [ ] `pyproject.toml` に依存パッケージが記載されている
- [ ] `uv.lock` が最新の状態である（`uv sync` で再現できる）
- [ ] `uv run` で実行できることを確認した

### 共通

- [ ] すべての関数に型ヒントがある（戻り値の `list[dict]` は `list[dict[str, Any]]` のように内部型まで明示）
- [ ] モジュール定数に `Final` アノテーションがある
- [ ] `Optional` / `List` / `Dict` など古い構文を使っていない
- [ ] 命名規則が PEP 8 に沿っている
- [ ] `uvx ruff check --fix` + `uvx ruff format` を実行した
- [ ] `uvx ty check` を実行してエラーがないことを確認した
- [ ] 前提条件・不変条件を assert で記述した（型で表現できない制約のみ）
