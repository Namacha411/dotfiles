# /// script
# dependencies = []
# requires-python = ">=3.12"
# ///
"""Zotero Local API と OpenAlex を叩く薄いヘルパー CLI。

読み取りは認証不要。書き込みは Zotero 10+ のローカル書き込み API を使い、
初回に Zotero 側で許可ダイアログが出る。詳細は SKILL.md / references/ を参照。
"""

import argparse
import html
import io
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Final

LOCAL_BASE: Final = "http://localhost:23119/api"
USER_PREFIX: Final = f"{LOCAL_BASE}/users/0"
OPENALEX_BASE: Final = "https://api.openalex.org"
KEY_FILE: Final = Path.home() / ".config" / "zotero-skill" / "local_key.json"
APP_NAME: Final = "Claude Code zotero skill"
AUTHORIZE_TIMEOUT: Final = 300  # ユーザーがダイアログを押すまで待つ
OA_LIST_FIELDS: Final = "id,doi,title,publication_year,cited_by_count,authorships"

type Json = Any


class ApiError(Exception):
    """HTTP エラーをステータスと本文付きで表す。"""

    def __init__(self, status: int, body: str, url: str) -> None:
        super().__init__(f"HTTP {status} for {url}: {body[:500]}")
        self.status = status
        self.body = body


# ---------------------------------------------------------------- HTTP


def request(
    method: str,
    url: str,
    body: Json | None = None,
    headers: dict[str, str] | None = None,
    timeout: float = 60,
) -> tuple[int, dict[str, str], bytes]:
    """HTTP リクエストを送り (status, headers, body) を返す。4xx/5xx は ApiError。"""
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method=method, headers=headers or {})
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            return res.status, dict(res.headers.items()), res.read()
    except urllib.error.HTTPError as e:
        raise ApiError(e.code, e.read().decode(errors="replace"), url) from e
    except urllib.error.URLError as e:
        if "localhost" in url:
            sys.exit(
                "Zotero に接続できません。Zotero が起動しているか、"
                "設定 → 詳細 →「他のアプリケーションと通信」が有効か確認してください。"
                f" ({e.reason})"
            )
        raise


def local_get(path: str, **params: str | int) -> Json:
    """Local API に GET して JSON を返す。path は /items/... のような users/0 以下。"""
    query = urllib.parse.urlencode({"format": "json", **params})
    _, _, raw = request("GET", f"{USER_PREFIX}{path}?{query}")
    return json.loads(raw)


def local_get_text(path: str, **params: str | int) -> str:
    query = urllib.parse.urlencode(params)
    _, _, raw = request("GET", f"{USER_PREFIX}{path}?{query}")
    return raw.decode()


def openalex_get(path: str, **params: str | int) -> Json:
    """OpenAlex に GET。OPENALEX_API_KEY があれば付与する。"""
    if key := os.environ.get("OPENALEX_API_KEY"):
        params["api_key"] = key
    query = urllib.parse.urlencode(params, safe=":|,/")
    _, _, raw = request("GET", f"{OPENALEX_BASE}{path}?{query}")
    return json.loads(raw)


# ---------------------------------------------------------------- write auth


def server_id() -> str:
    _, headers, _ = request("GET", f"{LOCAL_BASE}/")
    lowered = {k.lower(): v for k, v in headers.items()}
    return lowered["zotero-server-id"]


def load_key(sid: str) -> str | None:
    try:
        stored = json.loads(KEY_FILE.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    return stored.get(sid)


def authorize(sid: str) -> str:
    """Zotero に許可ダイアログを出して書き込みキーを得る。「常に許可」なら保存する。"""
    print("Zotero に書き込み許可ダイアログを表示しました。Zotero の画面で許可してください…", file=sys.stderr)
    try:
        _, _, raw = request(
            "POST",
            f"{LOCAL_BASE}/local/authorize",
            {"appName": APP_NAME},
            {"Zotero-Server-ID": sid},
            timeout=AUTHORIZE_TIMEOUT,
        )
    except ApiError as e:
        if e.status == 403:
            sys.exit("書き込みが拒否されました。")
        raise
    granted = json.loads(raw)
    if granted.get("remember"):
        KEY_FILE.parent.mkdir(parents=True, exist_ok=True)
        stored = json.loads(KEY_FILE.read_text(encoding="utf-8")) if KEY_FILE.exists() else {}
        stored[sid] = granted["key"]
        KEY_FILE.write_text(json.dumps(stored), encoding="utf-8")
    return granted["key"]


def local_write(
    method: str, path: str, body: Json | None = None, headers: dict[str, str] | None = None
) -> tuple[int, dict[str, str], Json]:
    """書き込みリクエスト。キーが無効(401)なら一度だけ再認可して再送する。"""
    sid = server_id()
    key = load_key(sid) or authorize(sid)
    for attempt in range(2):
        all_headers = {"Zotero-Server-ID": sid, "Zotero-API-Key": key, **(headers or {})}
        try:
            status, res_headers, raw = request(method, f"{USER_PREFIX}{path}", body, all_headers)
        except ApiError as e:
            if e.status == 401 and attempt == 0:
                key = authorize(sid)
                continue
            raise
        return status, res_headers, json.loads(raw) if raw.strip() else None
    raise AssertionError("unreachable")


def check_multi_result(result: Json) -> Json:
    """POST /items の multi-object 結果を検査し、失敗があれば終了する。"""
    if result.get("failed"):
        sys.exit(f"書き込み失敗: {json.dumps(result['failed'], ensure_ascii=False)}")
    return result


# ---------------------------------------------------------------- formatting


def creators_short(creators: list[dict[str, str]]) -> str:
    names = [c.get("lastName") or c.get("name", "") for c in creators]
    match names:
        case []:
            return ""
        case [only]:
            return only
        case [first, second]:
            return f"{first} & {second}"
        case _:
            return f"{names[0]} et al."


def year_of(date: str) -> str:
    return m.group(0) if (m := re.search(r"\d{4}", date or "")) else "n.d."


def item_line(data: dict[str, Any]) -> str:
    doi = item_doi(data)
    parts = [
        data["key"],
        data["itemType"],
        year_of(data.get("date", "")),
        creators_short(data.get("creators", [])),
        data.get("title", ""),
    ]
    return " | ".join(parts) + (f" | doi:{doi}" if doi else "")


def item_doi(data: dict[str, Any]) -> str | None:
    """DOI フィールド、extra、arXiv ID の順に DOI を推定する。"""
    if doi := data.get("DOI"):
        return doi.lower()
    if m := re.search(r"^DOI:\s*(\S+)", data.get("extra", ""), re.MULTILINE | re.IGNORECASE):
        return m.group(1).lower()
    for text in (data.get("archiveID", ""), data.get("extra", ""), data.get("url", "")):
        if m := re.search(r"arxiv[:./](?:abs/)?(\d{4}\.\d{4,5})", text, re.IGNORECASE):
            return f"10.48550/arxiv.{m.group(1)}"
    return None


def normalize_title(title: str) -> str:
    return re.sub(r"[^a-z0-9]", "", title.lower())


def print_json(obj: Json) -> None:
    print(json.dumps(obj, ensure_ascii=False, indent=2))


# ---------------------------------------------------------------- read commands


def cmd_search(args: argparse.Namespace) -> None:
    params: dict[str, str | int] = {"q": args.query, "limit": args.limit}
    if args.all:
        params["qmode"] = "everything"
    if args.tag:
        params["tag"] = args.tag
    base = f"/collections/{args.collection}" if args.collection else ""
    if not args.all:
        hits = local_get(f"{base}/items/top", **params)
        for item in hits:
            print(item_line(item["data"]))
        return
    # 全文検索は添付や注釈にもヒットするので、親アイテムへ寄せて重複を除く
    hits = local_get(f"{base}/items", **params)
    seen: dict[str, str] = {}
    for item in hits:
        top = resolve_top(item["data"])
        if top["key"] not in seen:
            seen[top["key"]] = item_line(top)
    print("\n".join(seen.values()))


def resolve_top(data: dict[str, Any]) -> dict[str, Any]:
    """注釈→添付→親 と辿ってトップレベルのアイテムを返す。"""
    while parent := data.get("parentItem"):
        data = local_get(f"/items/{parent}")["data"]
    return data


def children_of(key: str) -> list[dict[str, Any]]:
    return [c["data"] for c in local_get(f"/items/{key}/children")]


def attachment_path(key: str) -> str | None:
    item = local_get(f"/items/{key}")
    href = item.get("links", {}).get("enclosure", {}).get("href", "")
    if href.startswith("file:///"):
        return urllib.parse.unquote(href.removeprefix("file:///"))
    return None


def cmd_item(args: argparse.Namespace) -> None:
    data = local_get(f"/items/{args.key}")["data"]
    shown = {k: v for k, v in data.items() if v not in ("", [], {}) and k not in ("relations",)}
    print_json(shown)
    print("\n# children")
    for child in children_of(args.key):
        match child["itemType"]:
            case "attachment":
                n_ann = len(local_get(f"/items/{child['key']}/children", itemType="annotation"))
                path = attachment_path(child["key"]) or child.get("url", "")
                print(f"attachment {child['key']} {child.get('contentType', '')} annotations={n_ann} {path}")
            case "note":
                snippet = re.sub(r"<[^>]+>", " ", child.get("note", ""))[:80].strip()
                print(f"note {child['key']} {snippet}")
            case other:
                print(f"{other} {child['key']}")


def pdf_attachments(key: str) -> list[dict[str, Any]]:
    """key がアイテムなら子の PDF 等、添付ならそれ自身を返す。"""
    data = local_get(f"/items/{key}")["data"]
    if data["itemType"] == "attachment":
        return [data]
    return [c for c in children_of(key) if c["itemType"] == "attachment"]


def cmd_fulltext(args: argparse.Namespace) -> None:
    for att in pdf_attachments(args.key):
        try:
            text = local_get(f"/items/{att['key']}/fulltext")["content"]
        except ApiError as e:
            if e.status != 404:
                raise
            print(f"[{att['key']}] 全文インデックスなし。PDF を直接読む: {attachment_path(att['key'])}")
            continue
        print(f"===== {att['key']} {att.get('title', '')} =====")
        print(text)


def cmd_annotations(args: argparse.Namespace) -> None:
    for att in pdf_attachments(args.key):
        anns = local_get(f"/items/{att['key']}/children", itemType="annotation")
        anns.sort(key=lambda a: a["data"].get("annotationSortIndex", ""))
        for ann in anns:
            d = ann["data"]
            line = f"[p.{d.get('annotationPageLabel', '?')}] ({d['annotationType']}, {d.get('annotationColor', '')})"
            if text := d.get("annotationText"):
                line += f" {text}"
            if comment := d.get("annotationComment"):
                line += f"\n    comment: {comment}"
            print(line)


def cmd_notes(args: argparse.Namespace) -> None:
    for child in children_of(args.key):
        if child["itemType"] == "note":
            print(f"===== note {child['key']} =====\n{child['note']}")


def cmd_collections(_: argparse.Namespace) -> None:
    cols = [c["data"] for c in local_get("/collections")]
    by_key = {c["key"]: c for c in cols}

    def path_of(col: dict[str, Any]) -> str:
        parent = col.get("parentCollection")
        return f"{path_of(by_key[parent])} / {col['name']}" if parent else col["name"]

    for col in sorted(cols, key=path_of):
        print(f"{col['key']} | {path_of(col)}")


def cmd_cite(args: argparse.Namespace) -> None:
    if args.style == "bibtex":
        print(local_get_text(f"/items/{args.key}", format="bibtex"))
        return
    text = local_get_text(f"/items/{args.key}", format="bib", style=args.style, linkwrap=0)
    print(html.unescape(re.sub(r"<[^>]+>", "", text)).strip())


def cmd_get(args: argparse.Namespace) -> None:
    params = dict(urllib.parse.parse_qsl(args.query))
    print_json(local_get("/" + args.path.lstrip("/"), **params))


# ---------------------------------------------------------------- citations (OpenAlex)


def library_index() -> tuple[dict[str, str], dict[str, str]]:
    """ライブラリの DOI→key, 正規化タイトル→key の索引を作る。"""
    by_doi: dict[str, str] = {}
    by_title: dict[str, str] = {}
    for item in local_get("/items/top"):
        data = item["data"]
        if doi := item_doi(data):
            by_doi[doi] = data["key"]
        if title := data.get("title"):
            by_title[normalize_title(title)] = data["key"]
    return by_doi, by_title


def resolve_work(ref: str) -> dict[str, Any]:
    """Zotero key / DOI / arXiv ID / OpenAlex ID を OpenAlex の work に解決する。"""
    if re.fullmatch(r"W\d+", ref):
        return openalex_get(f"/works/{ref}")
    if m := re.fullmatch(r"(?:arxiv:)?(\d{4}\.\d{4,5})(v\d+)?", ref, re.IGNORECASE):
        ref = f"10.48550/arxiv.{m.group(1)}"
    if ref.lower().startswith(("10.", "doi:", "https://doi.org/")):
        doi = re.sub(r"^(doi:|https://doi\.org/)", "", ref, flags=re.IGNORECASE)
        return openalex_get(f"/works/doi:{doi}")
    data = local_get(f"/items/{ref}")["data"]
    if doi := item_doi(data):
        try:
            return openalex_get(f"/works/doi:{doi}")
        except ApiError as e:
            if e.status != 404:
                raise
    hits = search_by_title(data.get("title", ""))
    if not hits:
        sys.exit(f"OpenAlex で見つかりません: {data.get('title')}")
    print(f"(タイトル検索で解決: {hits[0]['title']} — 別論文の可能性に注意)", file=sys.stderr)
    return openalex_get(f"/works/{short_id(hits[0]['id'])}")


def search_by_title(title: str) -> list[dict[str, Any]]:
    """タイトルで OpenAlex を検索する。

    PDF 由来のタイトルは "forCommunity" のように語が癒着していたり、
    "GVE-Leiden: ..." のように出版版と接頭辞が異なったりするので、
    語の分割とサブタイトルのみの検索を順に試す。
    """
    unglued = re.sub(r"([a-z])([A-Z])", r"\1 \2", title)
    candidates = [title, unglued]
    if ":" in unglued:
        candidates.append(unglued.split(":", 1)[1])
    for candidate in dict.fromkeys(c.strip() for c in candidates):
        query = re.sub(r"[,|:]", " ", candidate)
        if hits := openalex_get("/works", filter=f"title.search:{query}", per_page=3)["results"]:
            return hits
    return []


def short_id(openalex_url: str) -> str:
    return openalex_url.rsplit("/", 1)[-1]


def work_line(work: dict[str, Any], index: tuple[dict[str, str], dict[str, str]]) -> str:
    by_doi, by_title = index
    doi = (work.get("doi") or "").removeprefix("https://doi.org/").lower()
    in_lib = by_doi.get(doi) or by_title.get(normalize_title(work.get("title") or ""))
    authors = [a["author"]["display_name"].split()[-1] for a in work.get("authorships", [])]
    author = authors[0] + (" et al." if len(authors) > 1 else "") if authors else ""
    mark = f"[in Zotero: {in_lib}]" if in_lib else ""
    return " | ".join(
        [
            short_id(work["id"]),
            str(work.get("publication_year")),
            author,
            work.get("title") or "",
            f"cited={work.get('cited_by_count')}",
            f"doi:{doi}" if doi else "",
            mark,
        ]
    ).rstrip(" |")


def cmd_oa(args: argparse.Namespace) -> None:
    work = resolve_work(args.ref)
    print_json(
        {
            "id": short_id(work["id"]),
            "doi": work.get("doi"),
            "title": work.get("title"),
            "year": work.get("publication_year"),
            "venue": ((work.get("primary_location") or {}).get("source") or {}).get("display_name"),
            "cited_by_count": work.get("cited_by_count"),
            "referenced_works_count": len(work.get("referenced_works", [])),
            "open_access_pdf": (work.get("best_oa_location") or {}).get("pdf_url"),
            "abstract": abstract_text(work),
        }
    )


def abstract_text(work: dict[str, Any]) -> str | None:
    """OpenAlex の abstract_inverted_index から本文を復元する。"""
    if not (inv := work.get("abstract_inverted_index")):
        return None
    positions = sorted((pos, word) for word, poss in inv.items() for pos in poss)
    return " ".join(word for _, word in positions)


def cmd_refs(args: argparse.Namespace) -> None:
    work = resolve_work(args.ref)
    ids = [short_id(w) for w in work.get("referenced_works", [])]
    print(f"# references of {short_id(work['id'])}: {work.get('title')} ({len(ids)} works)")
    index = library_index()
    works: list[dict[str, Any]] = []
    # openalex_id フィルタは 1 回 50 件まで OR 指定できる
    for start in range(0, len(ids), 50):
        chunk = "|".join(ids[start : start + 50])
        works += openalex_get("/works", filter=f"openalex_id:{chunk}", per_page=50, select=OA_LIST_FIELDS)["results"]
    for w in sorted(works, key=lambda w: -(w.get("cited_by_count") or 0)):
        print(work_line(w, index))
    if missing := len(ids) - len(works):
        print(f"# {missing} 件は OpenAlex 上で統合・削除済みのため取得できず")


def cmd_cites(args: argparse.Namespace) -> None:
    work = resolve_work(args.ref)
    sort = {"cited": "cited_by_count:desc", "recent": "publication_date:desc"}[args.sort]
    res = openalex_get(
        "/works",
        filter=f"cites:{short_id(work['id'])}",
        per_page=args.limit,
        sort=sort,
        select=OA_LIST_FIELDS,
    )
    print(f"# cited by {res['meta']['count']} works (showing {len(res['results'])}): {work.get('title')}")
    index = library_index()
    for w in res["results"]:
        print(work_line(w, index))


# ---------------------------------------------------------------- write commands


def cmd_authorize(_: argparse.Namespace) -> None:
    sid = server_id()
    if load_key(sid):
        print("保存済みの書き込みキーがあります。")
        return
    authorize(sid)
    print("書き込み許可を取得しました。" + ("" if load_key(sid) else "（1回限りの許可。次回も確認が出ます）"))


def to_note_html(text: str) -> str:
    """HTML ならそのまま、プレーンテキスト/Markdown なら段落ごとに <p> で包む。"""
    if text.lstrip().startswith("<"):
        return text
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    return "".join(f"<p>{html.escape(p).replace(chr(10), '<br>')}</p>" for p in paragraphs)


def cmd_add_note(args: argparse.Namespace) -> None:
    text = Path(args.file).read_text(encoding="utf-8") if args.file else args.text
    assert text, "--file か --text が必要"
    note: dict[str, Any] = {"itemType": "note", "note": to_note_html(text), "tags": [{"tag": t} for t in args.tag]}
    if args.parent:
        note["parentItem"] = args.parent
    _, _, result = local_write("POST", "/items", [note])
    created = check_multi_result(result)["successful"]["0"]
    print(f"ノートを作成しました: {created['key']}")


def cmd_tag(args: argparse.Namespace) -> None:
    item = local_get(f"/items/{args.key}")
    tags = [t for t in item["data"].get("tags", []) if t["tag"] not in args.remove]
    existing = {t["tag"] for t in tags}
    tags += [{"tag": t} for t in args.add if t not in existing]
    local_write("PATCH", f"/items/{args.key}", {"tags": tags}, {"If-Unmodified-Since-Version": str(item["version"])})
    print(f"{args.key} tags: {[t['tag'] for t in tags]}")


OA_TYPE_MAP: Final = {
    "article": "journalArticle",
    "preprint": "preprint",
    "book": "book",
    "book-chapter": "bookSection",
    "dissertation": "thesis",
    "report": "report",
    "dataset": "dataset",
}


def zotero_item_from_work(work: dict[str, Any]) -> dict[str, Any]:
    """OpenAlex の work を Zotero アイテム JSON に変換する。"""
    source = (work.get("primary_location") or {}).get("source") or {}
    is_proceedings = source.get("type") == "conference"
    item_type = "conferencePaper" if is_proceedings else OA_TYPE_MAP.get(work.get("type", ""), "journalArticle")
    biblio = work.get("biblio") or {}
    pages = "-".join(dict.fromkeys(p for p in (biblio.get("first_page"), biblio.get("last_page")) if p))
    item: dict[str, Any] = {
        "itemType": item_type,
        "title": work.get("title") or "",
        "creators": [creator_of(a["author"]["display_name"]) for a in work.get("authorships", [])],
        "date": work.get("publication_date") or str(work.get("publication_year") or ""),
        "url": work.get("doi") or "",
        "abstractNote": abstract_text(work) or "",
        "extra": f"OpenAlex: {short_id(work['id'])}",
    }
    doi = (work.get("doi") or "").removeprefix("https://doi.org/")
    venue = source.get("display_name") or ""
    match item_type:
        case "journalArticle":
            item |= {
                "DOI": doi,
                "publicationTitle": venue,
                "volume": biblio.get("volume") or "",
                "issue": biblio.get("issue") or "",
                "pages": pages,
            }
        case "conferencePaper":
            item |= {"DOI": doi, "proceedingsTitle": venue, "pages": pages}
        case "preprint":
            item |= {"DOI": doi, "repository": venue}
        case "bookSection":
            item |= {"bookTitle": venue, "pages": pages}
        case _:
            item["extra"] += f"\nDOI: {doi}" if doi else ""
    return item


def creator_of(display_name: str) -> dict[str, str]:
    *first, last = display_name.split() or [""]
    return {"creatorType": "author", "firstName": " ".join(first), "lastName": last}


def requested_doi(ref: str) -> str | None:
    """ユーザーが DOI / arXiv ID を直接指定した場合、その DOI を返す。"""
    if m := re.fullmatch(r"(?:arxiv:)?(\d{4}\.\d{4,5})(v\d+)?", ref, re.IGNORECASE):
        return f"10.48550/arXiv.{m.group(1)}"
    if ref.lower().startswith(("10.", "doi:", "https://doi.org/")):
        return re.sub(r"^(doi:|https://doi\.org/)", "", ref, flags=re.IGNORECASE)
    return None


def cmd_add(args: argparse.Namespace) -> None:
    work = resolve_work(args.ref)
    by_doi, by_title = library_index()
    doi = (work.get("doi") or "").removeprefix("https://doi.org/").lower()
    if dup := by_doi.get(doi) or by_title.get(normalize_title(work.get("title") or "")):
        sys.exit(f"既にライブラリにあります: {dup}")
    item = zotero_item_from_work(work)
    # OpenAlex は arXiv 版と出版版を統合して別 DOI を載せることがあるので、指定された DOI を優先する
    if (requested := requested_doi(args.ref)) and "DOI" in item:
        item["DOI"] = requested
        item["url"] = f"https://doi.org/{requested}"
    if args.collection:
        item["collections"] = [args.collection]
    if args.dry_run:
        print_json(item)
        return
    _, _, result = local_write("POST", "/items", [item])
    created = check_multi_result(result)["successful"]["0"]
    print(f"追加しました: {created['key']} | {item['title']}")


def cmd_write(args: argparse.Namespace) -> None:
    body = json.loads(Path(args.json).read_text(encoding="utf-8")) if args.json else None
    headers = dict(h.split(":", 1) for h in args.header)
    status, _, result = local_write(
        args.method.upper(), "/" + args.path.lstrip("/"), body, {k.strip(): v.strip() for k, v in headers.items()}
    )
    print(status)
    if result is not None:
        print_json(result)


# ---------------------------------------------------------------- CLI


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="zot", description=__doc__)
    sub = p.add_subparsers(required=True)

    s = sub.add_parser("search", help="ライブラリ検索")
    s.add_argument("query")
    s.add_argument("--all", action="store_true", help="全文・ノート・注釈も対象にする")
    s.add_argument("--limit", type=int, default=25)
    s.add_argument("--collection")
    s.add_argument("--tag")
    s.set_defaults(func=cmd_search)

    for name, func, help_ in [
        ("item", cmd_item, "メタデータと子アイテム(添付パス・ノート・注釈数)"),
        ("fulltext", cmd_fulltext, "Zotero の全文インデックスを出力"),
        ("annotations", cmd_annotations, "PDF のハイライト・コメント"),
        ("notes", cmd_notes, "子ノートの HTML"),
        ("oa", cmd_oa, "OpenAlex の書誌・被引用数・アブストラクト"),
        ("refs", cmd_refs, "参考文献一覧 (OpenAlex)"),
    ]:
        s = sub.add_parser(name, help=help_)
        s.add_argument("key" if name in ("item", "fulltext", "annotations", "notes") else "ref")
        s.set_defaults(func=func)

    s = sub.add_parser("cites", help="被引用一覧 (OpenAlex)")
    s.add_argument("ref")
    s.add_argument("--limit", type=int, default=25)
    s.add_argument("--sort", choices=["cited", "recent"], default="cited")
    s.set_defaults(func=cmd_cites)

    sub.add_parser("collections", help="コレクション一覧").set_defaults(func=cmd_collections)

    s = sub.add_parser("cite", help="参考文献表記")
    s.add_argument("key")
    s.add_argument("--style", default="apa", help="CSL スタイル名 (apa, ieee, nature …) または bibtex")
    s.set_defaults(func=cmd_cite)

    s = sub.add_parser("get", help="任意の Local API GET")
    s.add_argument("path", help="例: /items/top")
    s.add_argument("query", nargs="?", default="", help="例: 'limit=5&sort=dateAdded'")
    s.set_defaults(func=cmd_get)

    sub.add_parser("authorize", help="書き込み許可を取得").set_defaults(func=cmd_authorize)

    s = sub.add_parser("add-note", help="ノートを作成")
    s.add_argument("--parent", help="親アイテム key (省略で独立ノート)")
    s.add_argument("--file")
    s.add_argument("--text")
    s.add_argument("--tag", action="append", default=[])
    s.set_defaults(func=cmd_add_note)

    s = sub.add_parser("tag", help="タグの追加・削除")
    s.add_argument("key")
    s.add_argument("--add", action="append", default=[])
    s.add_argument("--remove", action="append", default=[])
    s.set_defaults(func=cmd_tag)

    s = sub.add_parser("add", help="DOI / arXiv / OpenAlex ID から論文を追加")
    s.add_argument("ref")
    s.add_argument("--collection")
    s.add_argument("--dry-run", action="store_true")
    s.set_defaults(func=cmd_add)

    s = sub.add_parser("write", help="任意の書き込みリクエスト")
    s.add_argument("method", choices=["POST", "PUT", "PATCH", "DELETE", "post", "put", "patch", "delete"])
    s.add_argument("path")
    s.add_argument("--json", help="リクエスト本文の JSON ファイル")
    s.add_argument("--header", action="append", default=[], help="'Name: value'")
    s.set_defaults(func=cmd_write)
    return p


def main() -> None:
    # Windows のコンソールは cp932 なので、日本語・記号を落とさないよう UTF-8 に固定する
    for stream in (sys.stdout, sys.stderr):
        if isinstance(stream, io.TextIOWrapper):
            stream.reconfigure(encoding="utf-8")
    args = build_parser().parse_args()
    try:
        args.func(args)
    except ApiError as e:
        sys.exit(str(e))


if __name__ == "__main__":
    main()
