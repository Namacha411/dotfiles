# API リファレンス（2026-10 に Zotero 10.0.6 で動作確認済み）

## 目次
1. Zotero Local API — 読み取り
2. Zotero Local API — 書き込み
3. OpenAlex
4. Semantic Scholar（予備）

公式: https://www.zotero.org/support/dev/web_api/v3/local_api ／ 書き込み形式は
https://www.zotero.org/support/dev/web_api/v3/write_requests 、パラメータは
https://www.zotero.org/support/dev/web_api/v3/basics

---

## 1. Zotero Local API — 読み取り

- ベース: `http://localhost:23119/api/users/0`（`0` = ローカルユーザー）。`/api/` 直下は `Nothing to see here.` が正常応答
- 認証不要。デフォルトで**ページングされない**（`limit` / `start` は有効）
- `format=json`（既定）, `keys`, `bibtex`, `bib`(+`style=apa` 等, `linkwrap=0`), `ris` など。Atom は 501
- `Zotero-Server-ID` ヘッダーが全レスポンスに付く

| エンドポイント | 用途・備考 |
|---|---|
| `GET /items/top?q=..&qmode=titleCreatorYear` | トップレベルのみ検索 |
| `GET /items?q=..&qmode=everything` | 全文・ノート・注釈にもヒット（添付や注釈そのものが返る → `parentItem` を辿る） |
| `GET /items/{key}` | 添付なら `links.enclosure.href` に `file:///…/storage/{key}/xxx.pdf` |
| `GET /items/{key}/children` | 添付・ノート。**注釈は含まれない** |
| `GET /items/{attKey}/children?itemType=annotation` | 注釈（注釈の親は PDF 添付） |
| `GET /items/{attKey}/fulltext` | `{"content": "..."}`。インデックス無しは 404 |
| `GET /items/{attKey}/file/view/url` | ローカルファイルの `file:///` URL |
| `GET /collections`, `/collections/{key}/items/top` | コレクション |
| `GET /tags`, `/searches`, `/items/trash` | タグ・保存検索・ゴミ箱 |
| `GET /items?itemType=-attachment`, `tag=foo`, `sort=dateAdded&direction=desc` | 絞り込み・並べ替え |

- 主な itemType: `journalArticle`, `preprint`, `conferencePaper`, `bookSection`, `book`, `thesis`, `report`, `webpage`, `attachment`, `note`, `annotation`
- arXiv プレプリントは `DOI: 10.48550/arXiv.XXXX`, `archiveID: arXiv:XXXX`, `extra` にカテゴリが入る
- PDF からインポートしたアイテムはタイトルの語が癒着していたり（`forCommunity`）、日付・DOI が空のことがある
- データディレクトリ: `C:\Users\thdyk\Zotero`（`storage\{attKey}\` に PDF、`zotero.sqlite` は起動中ロックされる — 直接書き込み厳禁）
- `items/new`（アイテムテンプレート）はローカルに無い → `https://api.zotero.org/items/new?itemType=journalArticle`（認証不要）で取得

## 2. Zotero Local API — 書き込み（Zotero 10+）

手順:
1. `GET /api/` で `Zotero-Server-ID` を得る
2. `POST /api/local/authorize`、本文 `{"appName": "..."}`、ヘッダー `Zotero-Server-ID` 必須 → ユーザーにダイアログ。
   許可で `{"key": "<32文字>", "remember": bool}`。`remember=false` は 1 回限り。拒否は 403 `{"denied": true}`。
   ダイアログを出すリクエストは 1 分 5 回まで（超過 429）
3. 書き込み時: `Zotero-Server-ID` と `Zotero-API-Key: <key>`（`Authorization: Bearer` も可）

| ステータス | 意味 |
|---|---|
| 428 | `Zotero-Server-ID` ヘッダーなし |
| 412 | Server-ID 不一致（別 DB）またはバージョン競合 → 再取得してやり直し |
| 401 | キー無効 → 再認可 |
| 403 | Local API 無効 / 認可拒否 |

操作（形式は Web API の Write Requests と同じ）:
- 作成: `POST /items` に配列（最大 50）。結果は `{"successful": {"0": {...}}, "failed": {...}}`。不正なフィールドは `failed` に入る
- 更新: `PATCH /items/{key}`（部分更新）/ `PUT`（全置換）＋ `If-Unmodified-Since-Version: <version>`
- ゴミ箱へ: `PATCH /items/{key}` に `{"deleted": 1}`。戻すのは `{"deleted": 0}`
- 完全削除: `DELETE /items/{key}` ＋ `If-Unmodified-Since-Version`（204）。ゴミ箱を経由しない
- コレクション: `POST /collections` に `[{"name": "...", "parentCollection": "KEY"}]`。アイテムを入れるには item の `collections` 配列を PATCH
- ノート: `{"itemType": "note", "parentItem": "KEY", "note": "<p>HTML</p>", "tags": [{"tag": "x"}]}`
- 全文: `PUT /items/{attKey}/fulltext`
- ファイル添付: `POST /items/{key}/file`（md5, filename, filesize, mtime ＋ `If-None-Match: *`）→ 返された url にバイト列を POST → `upload=<uploadKey>` で確定。`imported_file` / `imported_url` 添付のみ
- 書き込みは即座に UI に反映され、次回同期で zotero.org に送られる。ローカルの version は Web API の version と無関係

## 3. OpenAlex

ベース `https://api.openalex.org`。キーなしで $0.10/日、無料キー（openalex.org/settings/api）で $1/日。
キーは環境変数 `OPENALEX_API_KEY` に入れれば `zot.py` が付与する。残量はレスポンスヘッダー `X-RateLimit-Remaining-USD`。

| 呼び出し | 料金 | 例 |
|---|---|---|
| 単体取得 | 無料 | `/works/doi:10.1038/s41598-019-41695-z`, `/works/W2897249806` |
| 一覧・フィルタ | $0.0001 | `/works?filter=cites:W2897249806&sort=cited_by_count:desc&per_page=25` |
| 参考文献の一括取得 | $0.0001 | `/works?filter=openalex_id:W1\|W2\|…`（50 件まで） |
| タイトル検索 | $0.0001 | `/works?filter=title.search:...` |
| 全文的検索 | $0.001 | `/works?search=...` |

- `select=id,doi,title,publication_year,cited_by_count,authorships` で応答を軽くする
- 単体取得の `referenced_works` が参考文献 ID 一覧。アブストラクトは `abstract_inverted_index` を復元
- `best_oa_location.pdf_url` にオープンアクセス PDF
- 癖: arXiv 版は参考文献・被引用が 0 件になりやすい。出版版と統合されて別 DOI・別年が付くことがある
  （例: arXiv:1706.03762 → DOI 10.65215/…、2025 年）。`ids.arxiv` フィルタは存在しない

## 4. Semantic Scholar（予備）

キーなしは共有プールで頻繁に 429 になる（2026-10 時点で実測）。使うなら無料キーを取得して `x-api-key` ヘッダーで送る。

```
GET https://api.semanticscholar.org/graph/v1/paper/arXiv:1706.03762?fields=title,year,citationCount,externalIds
GET https://api.semanticscholar.org/graph/v1/paper/DOI:10.xxx/references?fields=title,year,externalIds&limit=100
GET https://api.semanticscholar.org/graph/v1/paper/DOI:10.xxx/citations?fields=title,year,citationCount&limit=100
```

arXiv 論文の引用関係は OpenAlex より Semantic Scholar の方が充実していることが多い。
