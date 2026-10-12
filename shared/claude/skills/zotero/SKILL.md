---
name: zotero
description: ユーザーの Zotero ライブラリ（Zotero 10 Local API）と OpenAlex を使って、論文の検索・本文取得・ハイライト/ノート参照・参考文献(引用)と被引用の調査・要約・翻訳・解説・引用表記の生成・ノートやタグの書き込み・論文の追加を行う。「Zotero」「ライブラリの論文」「この論文を要約/翻訳/解説して」「被引用を調べて」「関連論文」「参考文献リスト」「BibTeX」「ノートに保存」など、ユーザーが手元の論文や文献管理に触れたら、Zotero と明示されていなくても必ずこのスキルを使うこと。論文タイトルや DOI・arXiv ID が出てきて内容理解や引用関係を求められた場合も対象。
---

# Zotero

Zotero デスクトップ(10.x)が `http://localhost:23119/api/` で公開する Local API（Web API v3 互換）と、
引用関係用の OpenAlex API を、同梱のヘルパー `scripts/zot.py` 経由で使う。
要約・翻訳・解説そのものは Claude が本文を読んで行う。スクリプトは「データを正しく取ってくる」ことだけを担う。

## 前提

- Zotero が起動していること。接続エラーなら、起動と「設定 → 詳細 → このコンピュータ上の他のアプリケーションが Zotero と通信できるようにする」を確認してもらう
- 実行: `uv run ~/.claude/skills/zotero/scripts/zot.py <command> ...`（以下 `zot` と略記。標準ライブラリのみ）
- Git Bash では `/items/...` のような先頭スラッシュ付き引数がパス変換で壊れる。`items/top` のようにスラッシュなしで渡す

## コマンド

| 目的 | コマンド |
|---|---|
| メタデータ検索（タイトル・著者・年） | `zot search "leiden" [--limit N] [--collection KEY] [--tag T]` |
| 全文・ノート・注釈も含めて検索 | `zot search "modularity" --all` （ヒットは親アイテムにまとめて表示） |
| アイテム詳細＋添付 PDF のパス・ノート・注釈数 | `zot item KEY` |
| 本文テキスト（Zotero の全文インデックス） | `zot fulltext KEY` （アイテム key でも添付 key でも可） |
| ユーザーのハイライト・コメント | `zot annotations KEY` |
| 子ノート | `zot notes KEY` |
| コレクション一覧 | `zot collections` |
| 引用表記 | `zot cite KEY [--style apa\|ieee\|nature\|bibtex …]` |
| 任意の GET | `zot get items/top "sort=dateAdded&direction=desc&limit=10"` |
| OpenAlex 書誌・被引用数・アブストラクト・OA PDF | `zot oa KEY\|DOI\|arXiv:ID\|W123` |
| 参考文献（この論文が引用している論文） | `zot refs KEY\|DOI\|…` |
| 被引用（この論文を引用している論文） | `zot cites KEY\|DOI\|… [--limit N] [--sort cited\|recent]` |
| ノート作成 | `zot add-note --parent KEY --file note.html [--tag T]` （`--text` も可。プレーンテキストは段落ごとに `<p>` 化） |
| タグ追加・削除 | `zot tag KEY --add T --remove T` |
| DOI/arXiv から論文追加 | `zot add DOI [--collection KEY] [--dry-run]` |
| 任意の書き込み | `zot write PATCH items/KEY --json body.json --header "If-Unmodified-Since-Version: N"` |

`refs` / `cites` の各行末の `[in Zotero: KEY]` は、その論文が既にライブラリにあることを示す（DOI かタイトルで照合）。

## 作業の進め方

### 論文の特定
ユーザーの言い方（タイトルの一部、著者、「この前入れたやつ」）から `zot search` で候補を出す。
複数ヒットして曖昧なら候補を見せて確認する。新しく入れた論文は `zot get items/top "sort=dateAdded&direction=desc&limit=5"`。

### 要約・翻訳・解説
1. `zot item KEY` で全体像を把握する
2. 本文は `zot fulltext KEY` を使う。全文インデックスが無い場合は表示された PDF パスを Read で読む
   （長い論文は出力をスクラッチパッドのファイルに保存し、節ごとに読むとコンテキストを圧迫しない）
3. `zot annotations KEY` と `zot notes KEY` も確認する。ユーザー自身のハイライトやメモは、
   その人がどこに関心を持っているかを示すので、要約や解説の焦点合わせに使う。既に日本語訳のメモがあれば重複させない
4. 出力はチャットに日本語で返す。Zotero への保存はユーザーに頼まれたときだけ行う

数値・手法名・主張は本文に書かれている内容に基づかせ、推測で補う場合はそう明記する。
要約に使った本文がアブストラクトだけなら、それも明記する。

### 引用・被引用の調査
- `zot refs` / `zot cites` を使う。被引用が多い論文は `--sort cited` で影響力の大きいものから、最新動向なら `--sort recent`
- DOI の無いアイテムはタイトル検索で OpenAlex に解決する。その場合は stderr に「タイトル検索で解決」と出るので、
  解決結果のタイトル・年が正しいかを確認してからユーザーに示す
- **arXiv プレプリントは OpenAlex 上で参考文献・被引用が 0 件になりがち**（引用は出版版に付く）。
  0 件なら出版版がないか `zot oa` の結果やタイトル検索で探す。それでも駄目なら Semantic Scholar を試す（references/api.md）
- 被引用論文を「ライブラリに追加して」と言われたら `zot add`（下記）

### 書き込み
書き込みはユーザーのライブラリ（同期されていれば zotero.org にも）に残るので、ユーザーが明示的に頼んだ操作だけ行う。
- 初回は Zotero に許可ダイアログが出る。「常に許可」ならキーが `~/.config/zotero-skill/local_key.json` に保存され以後不要。
  拒否されたら無理に再試行しない。権限は Zotero 設定の「書き込み権限のクリア」で取り消せる
- ノートは HTML。要約を保存する場合は見出し・箇条書きを HTML タグで書いたファイルを作って `--file` で渡す
- `zot add` のメタデータは OpenAlex 由来で、arXiv 論文では年や DOI がずれることがある（指定した DOI は優先して保持）。
  追加前に `--dry-run` で内容を見せる。厳密な書誌が必要なら Zotero の「識別子でアイテムを追加」（魔法の杖ボタン）を勧める
- 削除: `DELETE` は**ゴミ箱を経由しない完全削除**。ユーザーの「削除」は基本的にゴミ箱移動
  （`PATCH` で `{"deleted": 1}`）として扱い、完全削除は明示されたときだけ
- `PATCH`/`DELETE` には `If-Unmodified-Since-Version`（`zot get items/KEY` の `version`）が必要。`zot tag` は自動で付ける

## 詳細リファレンス

生のエンドポイント、ヘッダー、エラーコード、OpenAlex / Semantic Scholar の呼び方と料金は
`references/api.md` にある。スクリプトに無い操作（コレクション作成、保存検索、全文書き込み、ファイル添付など）を
する場合や、エラーの意味を調べる場合に読む。
