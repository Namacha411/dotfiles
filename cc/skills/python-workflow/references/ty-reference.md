# ty リファレンス

Astral 製の Rust 実装型チェッカー。mypy / pyright より 10〜100x 高速で、`uvx` で都度実行できるためインストール不要。

公式ドキュメント: https://docs.astral.sh/ty/

---

## 基本コマンド

```bash
# ファイル単体をチェック
uvx ty check script.py

# ディレクトリ全体をチェック
uvx ty check src/

# カレントディレクトリをチェック
uvx ty check .
```

---

## 主要フラグ

| フラグ | 説明 | 例 |
|---|---|---|
| `--python-version` | チェック対象の Python バージョン | `--python-version 3.12` |
| `--output-format` | 出力フォーマット（`full` / `concise` / `json`） | `--output-format concise` |
| `--watch` | ファイル変更を監視して自動再チェック | `--watch` |

```bash
# Python バージョンを指定
uvx ty check --python-version 3.12 script.py

# watch モード（ファイル変更を監視）
uvx ty check --watch script.py

# JSON 形式で出力（CI 連携など）
uvx ty check --output-format json script.py
```

---

## Exit Codes

| コード | 意味 |
|---|---|
| `0` | エラーなし（警告のみの場合も含む） |
| `1` | 型エラーあり |
| `2` | 設定エラー / 無効なオプション |

---

## `pyproject.toml` での設定

```toml
[tool.ty]
# チェック対象ディレクトリ
src = ["src", "scripts"]

[tool.ty.environment]
python-version = "3.12"

[tool.ty.rules]
# ルール重大度: "error" | "warn" | "ignore"
division-by-zero = "error"
possibly-unbound = "warn"
```

---

## 主なエラーコード

| エラーコード | 説明 |
|---|---|
| `invalid-argument-type` | 関数引数の型不一致 |
| `invalid-return-type` | 戻り値の型不一致 |
| `invalid-assignment` | 変数への代入時の型不一致 |
| `possibly-unbound` | 未束縛の可能性がある変数 |
| `possibly-unresolved-reference` | 未解決の参照 |
| `division-by-zero` | ゼロ除算の可能性 |

---

## ルール重大度

各ルールに `"error"` / `"warn"` / `"ignore"` を設定できる。

```toml
[tool.ty.rules]
# 無視したいルール
possibly-unbound = "ignore"

# 警告として扱う（exit code 0 になる）
invalid-return-type = "warn"
```

---

## ruff との組み合わせ

ty は型チェック、ruff は lint / format を担当する。両者は補完関係にある。

```bash
# 推奨ワークフロー
uvx ruff check --fix script.py && uvx ruff format script.py && uvx ty check script.py
```
