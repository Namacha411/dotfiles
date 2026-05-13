---
name: python-best-practices
description: >
  Python を書く際に適用するベストプラクティス。
  使い捨て単一スクリプトには uv + PEP 723、それ以外のプロジェクトには uv init + uv add で環境を構築し、
  型ヒントと PEP 8 スタイルでコードの品質・可読性・保守性を確保する。
  Python ファイルの新規作成、既存スクリプトの修正、依存パッケージの追加など、
  Python に関わる作業が発生したら必ずこのスキルを参照すること。
---

# Python Workflow

このスキルの目的は「未来の自分や他者がそのスクリプトを読んだとき、迷わず理解・修正できる」コードを書くことにある。
そのために uv で再現性を、型ヒントで静的解析可能性を、PEP 8 で一貫したスタイルを担保する。

Python はあくまで高機能なスクリプト言語であり、システムプログラミング言語ではない。
その場しのぎの使い捨てスクリプトとしてまずは小さく実装・実行できることを最重要視する。
一方で、拡張や転用、再利用を重ねるうちに価値のあるプログラムへと進化できる言語でもある。
そのため、長期的に見たときに保守できるよう常に盤石な品質に仕上げ、ロバストネスを高める。

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

### `if __name__ == "__main__":` ガード

**本体処理は必ず `if __name__ == "__main__":` で囲む。**

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
uv sync                  # uv.lock から venv を再現（git clone 後など）
```

### 実行方法

```bash
uv run python main.py       # スクリプトを実行
uv run python -m mypackage  # モジュールとして実行
```

---

## 4. 型ヒント

型ヒントにより LSP の補完と静的型検査が有効になる。

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

## 7. assert の使いどころ

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

## 8. コーディングのベストプラクティス

### 8.1 ヘルパー関数で複雑な式を分割する

Python では多数のロジックを備えた複雑な式をワンライナーで書ける（例: `int(values.get("red", [""])[0] or 0)`）。
しかしこれは読みにくく、保守性が低い。式が複雑になった場合はより小さなパーツに分割し、ヘルパー関数へ移植する。
これは DRY 原則を守ることにもつながる。

### 8.2 代入式（セイウチ演算子）で重複を防ぐ

代入式はセイウチ演算子 `:=` を使って変数の代入と評価を 1 つの式で行うため重複を削除できる。
`if` 文・`while` 文の条件式に使うと変数のスコープが明確になり、冗長性が排除される。

```python
# while でバッファを読み切る
while chunk := file.read(8192):
    process(chunk)

# if でパターンマッチ的に使う
if m := re.match(r"(\d+)", line):
    print(m.group(1))
```

### 8.3 パターンマッチで制御構造を分割する

#### インデックス参照でなくアンパックを使う

シーケンスへのインデックス参照の代わりにアンパックを使うとコードが読みやすくなり意味が明瞭になる。

```python
# 避ける
first = items[0]
rest = items[1:]

# 使う
first, *rest = items
```

#### パターンマッチによる分割

```python
# 愚直な実装
def contains(tree, value):
    if not isinstance(tree, tuple):
        return tree == value
    pivot, left, right = tree
    if value < pivot:
        return contains(left, value)
    return contains(right, value)

# パターンマッチによる分割（冗長性排除・網羅性が明確）
def contains(tree, value):
    match tree:
        case pivot, left, _ if value < pivot:
            return contains(left, value)
        case (pivot, _, right) if value > pivot:
            return contains(right, value)
        case (pivot, _, _) | pivot:
            return pivot == value
```

詳細な活用事例: https://peps.python.org/pep-0636/

#### スライスではなく catch-all unpack を使う

リストを重複なく分割したい場合、インデックスやスライスの組み合わせよりも catch-all unpack を使う。
実行時エラーが発生しにくく、汎用性が高い。

```python
# 避ける（IndexError の可能性）
head = items[0]
tail = items[1:]

# 使う（空リストでも安全）
head, *tail = items
```

### 8.4 関数引数のイミュータビリティ

Python の関数引数はミュータブルなオブジェクトを参照渡しするため、呼び出し元の値が意図せず変更される可能性がある。

1. 自分で関数を実装する際には、引数を変更しないことを型ヒントや命名で明示する
2. 外部関数を利用する場合、必要に応じて `arr[:]` や `dic.copy()` で防御的コピーを作る
3. データ構造を設計する際には、防御的コピーを簡単に作れるヘルパーメソッドを用意する

```python
from dataclasses import dataclass, field

@dataclass(frozen=True)  # イミュータブルにする
class Config:
    values: tuple[str, ...] = field(default_factory=tuple)
```

### 8.5 シンプルなインターフェースには関数を使う

Python の関数・メソッドは第一級オブジェクトなので、コンポーネント間の単純なインターフェースとして利用できる。
引数が 1 つ程度の場合はクラスではなく関数を定義するほうが実装コストが低い。

状態を持たせたい場合は `__call__()` を持つクラスを定義すると関数のように呼び出せる。

```python
class Multiplier:
    def __init__(self, factor: int) -> None:
        self.factor = factor

    def __call__(self, value: int) -> int:
        return value * self.factor

double = Multiplier(2)
print(double(5))  # 10
```

### 8.6 関数型シングルディスパッチ

`functools.singledispatch` を使うと、型に応じたディスパッチを関数ベースで実現できる。
オブジェクト指向のポリモーフィズムはクラス中心の分散した構造になるが、
シングルディスパッチは関連する機能をソースコード内に凝縮できる。

同じデータ上で動作する独立した複数のシステムを持つプログラムに対して特に有効。

```python
from functools import singledispatch

@singledispatch
def evaluate(node):
    raise NotImplementedError(f"Unknown node type: {type(node)}")

@evaluate.register
def _(node: IntegerNode) -> int:
    return node.value

@evaluate.register
def _(node: AddNode) -> int:
    return evaluate(node.left) + evaluate(node.right)
```

### 8.7 例外処理の注意点

- 例外処理は大きなオーバーヘッドがかかることを意識する
- `try` ブロックを可能な限り短く保つ（詰め込みすぎると意図しない例外を補足してしまう）
- `except` ブロックも最小限に保つ（詰め込みすぎると意図しない問題を握りつぶす恐れがある）
- 「実際に何が起きた」を補足できるようにする（例外の表示やログへの記録）

```python
# 避ける（広すぎる try）
try:
    data = load(path)
    result = process(data)
    save(result, output)
except Exception as e:
    print(e)

# 使う（最小限の try）
try:
    data = load(path)
except FileNotFoundError as e:
    print(f"File not found: {e}")
    raise
result = process(data)
save(result, output)
```

### 8.8 デバッグ（pdb）

コマンドラインで `pdb` をモジュールとして起動したり、プログラム内部で `pdb.pm()` を呼び出すと
ポストモーテムデバッグができる。

```bash
# スクリプトをデバッガで実行
python -m pdb script.py

# 例外発生後にポストモーテム
python -c "import pdb, script; pdb.pm()"
```

### 8.9 docstring の書き方

型アノテーションで表現できる部分は docstring ではなく型アノテーションで表現する。
docstring には以下を明記する:

- **モジュール**: モジュールの内容、ユーザが知るべき重要なクラスや関数の説明
- **クラス**: 重要な属性、派生クラスとその動作
- **関数**: 全ての引数・返り値・発生しうる例外・動作

### 8.10 避けるべき記法

直観的でなく、バグや誤読の原因になるため避ける:

- `for` / `while` ループ後の `else` ブロック
- ループ終了後のループ変数の使用
- 辞書型に対して挿入順序に依存したコードを書く（順序が重要なら明示する）
- 辞書・リスト・タプルを深くネストしたデータ構造での状態管理
- 関数の引数・返り値が 4 つ以上になる場合（`class` への切り出しを検討）
- 多重継承

#### 文字列の暗黙的な結合は使わない

```python
# 避ける（要素数が 3 に見えるが実は 2）
arr = [
    "line1",
    "line2"
    "line3",
]

# 使う（明示的に結合）
arr = [
    "line1",
    "line2" + "line3",
]
```

#### イテレート中のコンテナの変更

意図しない挙動・バグの原因になる。代わりにコピーやキャッシュを使う。

```python
# 避ける
for item in my_list:
    if condition(item):
        my_list.remove(item)  # イテレート中の変更

# 使う
my_list = [item for item in my_list if not condition(item)]
```

### 8.11 積極的に使用を考えるもの

| 機能 | 理由 |
|---|---|
| `any()`, `all()` | 効率的な短絡評価 |
| `itertools` | 高性能なイテレータ操作（https://docs.python.org/3/library/itertools.html）|
| `dataclasses` | 落とし穴を回避しつつ実装コストを抑える（`frozen=True` で明示的なイミュータブル）|
| 関数型プログラミングスタイル | ロバストネス・テスタビリティの向上 |
| `logging` による警告 | API 変更時に自分・他開発者への明瞭な通知でリファクタリングを促進 |

---

## 参考ドキュメント

| ツール / 仕様     | URL |
|------------------|-----|
| uv               | https://docs.astral.sh/uv/ |
| PEP 723          | https://peps.python.org/pep-0723/ |
| PEP 636          | https://peps.python.org/pep-0636/ |
| PEP 8            | https://peps.python.org/pep-0008/ |
| typing モジュール | https://docs.python.org/3/library/typing.html |
| collections.abc  | https://docs.python.org/3/library/collections.abc.html |
| itertools        | https://docs.python.org/3/library/itertools.html |
| dataclasses      | https://docs.python.org/3/library/dataclasses.html |
| logging          | https://docs.python.org/3/library/logging.html |

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
- [ ] 前提条件・不変条件を assert で記述した（型で表現できない制約のみ）
- [ ] 複雑なワンライナー式はヘルパー関数に分割した
- [ ] 関数の引数を意図せず変更していない（必要に応じて防御的コピーを使用）
- [ ] 例外の try/except ブロックを最小限に保っている
- [ ] 直観的でない記法（for/while の else、暗黙的な文字列結合 等）を使っていない
