# /// script
# dependencies = [
#   "requests>=2.31",
#   "python-dotenv>=1.0",
#   "fugashi[unidic-lite]",
# ]
# requires-python = ">=3.9"
# ///

from __future__ import annotations

import json
import os
import re
import sys
import time
from pathlib import Path

import requests
from dotenv import load_dotenv

BASE_URL = "http://localhost:32766/api/talk/v1"
LANGUAGE = "ja_JP"
MAX_TEXT_LEN = 500
POLL_INTERVAL = 0.5
POLL_TIMEOUT = 60.0

_STATE_FILE = Path(os.environ.get("TEMP", str(Path.home()))) / "tts_hook_state.json"

# ── English → katakana ────────────────────────────────────────────────────────

_EN_KANA: dict[str, str] = {
    # Claude Code
    "transcript": "トランスクリプト",
    "hook": "フック",
    "hooks": "フックス",
    "agent": "エージェント",
    "agents": "エージェンツ",
    "skill": "スキル",
    "skills": "スキルズ",
    "plugin": "プラグイン",
    "plugins": "プラグインズ",
    "session": "セッション",
    "matcher": "マッチャー",
    "stop": "ストップ",
    "command": "コマンド",
    "commands": "コマンドズ",
    "model": "モデル",
    "context": "コンテキスト",
    "token": "トークン",
    "tokens": "トークンズ",
    "tool": "ツール",
    "tools": "ツールズ",
    "message": "メッセージ",
    "messages": "メッセージズ",
    "content": "コンテント",
    "stream": "ストリーム",
    "chunk": "チャンク",
    "chunks": "チャンクス",
    "prompt": "プロンプト",
    # Files / paths
    "file": "ファイル",
    "files": "ファイルズ",
    "path": "パス",
    "directory": "ディレクトリ",
    "folder": "フォルダ",
    "script": "スクリプト",
    "scripts": "スクリプツ",
    "log": "ログ",
    "logs": "ログズ",
    "config": "コンフィグ",
    "settings": "セッティングズ",
    "setup": "セットアップ",
    "symlink": "シンボリックリンク",
    # Programming
    "code": "コード",
    "debug": "デバッグ",
    "error": "エラー",
    "errors": "エラーズ",
    "test": "テスト",
    "build": "ビルド",
    "deploy": "デプロイ",
    "install": "インストール",
    "update": "アップデート",
    "version": "バージョン",
    "import": "インポート",
    "export": "エクスポート",
    "function": "ファンクション",
    "method": "メソッド",
    "class": "クラス",
    "module": "モジュール",
    "package": "パッケージ",
    "library": "ライブラリ",
    "framework": "フレームワーク",
    "instance": "インスタンス",
    "object": "オブジェクト",
    "array": "アレイ",
    "list": "リスト",
    "dict": "ディクト",
    "string": "ストリング",
    "type": "タイプ",
    "async": "エイシンク",
    "await": "アウェイト",
    "callback": "コールバック",
    "handler": "ハンドラー",
    "listener": "リスナー",
    "event": "イベント",
    "flag": "フラッグ",
    "option": "オプション",
    "options": "オプションズ",
    "argument": "アーギュメント",
    "parameter": "パラメーター",
    "buffer": "バッファ",
    "thread": "スレッド",
    "process": "プロセス",
    "runtime": "ランタイム",
    "template": "テンプレート",
    "format": "フォーマット",
    "parse": "パース",
    "render": "レンダー",
    "compile": "コンパイル",
    "interface": "インターフェース",
    "schema": "スキーマ",
    "task": "タスク",
    "worker": "ワーカー",
    "queue": "キュー",
    "cache": "キャッシュ",
    "state": "ステート",
    "mock": "モック",
    "stub": "スタブ",
    # Network / API
    "api": "エーピーアイ",
    "url": "ユーアールエル",
    "http": "エイチティーティーピー",
    "https": "エイチティーティーピーエス",
    "server": "サーバー",
    "client": "クライアント",
    "request": "リクエスト",
    "response": "レスポンス",
    "status": "ステータス",
    "header": "ヘッダー",
    "body": "ボディ",
    "post": "ポスト",
    "get": "ゲット",
    "put": "プット",
    "delete": "デリート",
    "patch": "パッチ",
    "host": "ホスト",
    "port": "ポート",
    "proxy": "プロキシ",
    "timeout": "タイムアウト",
    "socket": "ソケット",
    "rest": "レスト",
    "graphql": "グラフキューエル",
    "websocket": "ウェブソケット",
    "cors": "コルス",
    "json": "ジェイソン",
    "xml": "エックスエムエル",
    "yaml": "ヤムル",
    "toml": "トムル",
    # Git
    "git": "ギット",
    "commit": "コミット",
    "push": "プッシュ",
    "pull": "プル",
    "branch": "ブランチ",
    "merge": "マージ",
    "clone": "クローン",
    "repo": "レポ",
    "repository": "リポジトリ",
    # Shell / OS
    "bash": "バッシュ",
    "shell": "シェル",
    "env": "エンブ",
    "stdin": "スタンダードイン",
    "stdout": "スタンダードアウト",
    "stderr": "スタンダードエラー",
    "powershell": "パワーシェル",
    "terminal": "ターミナル",
    "linux": "リナックス",
    "windows": "ウィンドウズ",
    "docker": "ドッカー",
    "container": "コンテナ",
    "image": "イメージ",
    # Languages / tools
    "python": "パイソン",
    "javascript": "ジャバスクリプト",
    "typescript": "タイプスクリプト",
    "rust": "ラスト",
    "golang": "ゴーラング",
    "java": "ジャバ",
    "kotlin": "コトリン",
    "swift": "スウィフト",
    "ruby": "ルビー",
    "uv": "ユーブイ",
    "pip": "ピップ",
    "npm": "エヌピーエム",
    "node": "ノード",
    "css": "シーエスエス",
    "html": "エイチティーエムエル",
    # Abbreviations
    "id": "アイディー",
    "uuid": "ユーユーアイディー",
    "ai": "エーアイ",
    "llm": "エルエルエム",
    "tts": "ティーティーエス",
    "cli": "シーエルアイ",
    "ui": "ユーアイ",
    "os": "オーエス",
    "ok": "オーケー",
    "mcp": "エムシーピー",
    "sdk": "エスディーケー",
    "utf": "ユーティーエフ",
    "ascii": "アスキー",
    # Actions / states
    "create": "クリエート",
    "read": "リード",
    "write": "ライト",
    "open": "オープン",
    "close": "クローズ",
    "save": "セーブ",
    "load": "ロード",
    "send": "センド",
    "run": "ラン",
    "start": "スタート",
    "restart": "リスタート",
    "enable": "イネーブル",
    "disable": "ディセーブル",
    "active": "アクティブ",
    "match": "マッチ",
    "filter": "フィルター",
    "sort": "ソート",
    "search": "サーチ",
    "query": "クエリ",
    "result": "リザルト",
    "results": "リザルツ",
    "item": "アイテム",
    "items": "アイテムズ",
    "count": "カウント",
    "limit": "リミット",
    "offset": "オフセット",
    "mode": "モード",
    "profile": "プロフィール",
    "warning": "ワーニング",
    "info": "インフォ",
    "trace": "トレース",
    "verbose": "バーボース",
    "release": "リリース",
    "stable": "ステーブル",
    "beta": "ベータ",
    "alpha": "アルファ",
    "feature": "フィーチャー",
    "bug": "バグ",
    "fix": "フィックス",
    "issue": "イシュー",
    "review": "レビュー",
    "refactor": "リファクター",
    "clean": "クリーン",
    "check": "チェック",
    "abort": "アボート",
    "cancel": "キャンセル",
    "confirm": "コンファーム",
    "skip": "スキップ",
    "ignore": "イグノア",
    "allow": "アロウ",
    "deny": "デナイ",
    "block": "ブロック",
    "redirect": "リダイレクト",
    "fallback": "フォールバック",
    "retry": "リトライ",
    "delay": "ディレイ",
    "interval": "インターバル",
    "trigger": "トリガー",
    "signal": "シグナル",
    "monitor": "モニター",
    "alert": "アラート",
    "metric": "メトリック",
    "metrics": "メトリックス",
    "name": "ネーム",
    "user": "ユーザー",
    "users": "ユーザーズ",
    "password": "パスワード",
    "auth": "オース",
    "global": "グローバル",
    "local": "ローカル",
    "remote": "リモート",
    "cloud": "クラウド",
    "network": "ネットワーク",
    "service": "サービス",
    "dependency": "ディペンデンシー",
    "dependencies": "ディペンデンシーズ",
    "namespace": "ネームスペース",
    "scope": "スコープ",
    "production": "プロダクション",
    "staging": "ステージング",
    "development": "デベロップメント",
    "data": "データ",
    "input": "インプット",
    "output": "アウトプット",
    "memory": "メモリ",
    "disk": "ディスク",
    "pipeline": "パイプライン",
    "batch": "バッチ",
    "job": "ジョブ",
    "scheduler": "スケジューラー",
    "cron": "クロン",
    "poll": "ポール",
    "polling": "ポーリング",
    "lock": "ロック",
    "unlock": "アンロック",
    "hash": "ハッシュ",
    "base": "ベース",
    "index": "インデックス",
    "key": "キー",
    "value": "バリュー",
    "null": "ヌル",
    "true": "トゥルー",
    "false": "フォルス",
    "none": "ノン",
    "boolean": "ブーリアン",
    "number": "ナンバー",
    "new": "ニュー",
    "main": "メイン",
    "default": "デフォルト",
    "static": "スタティック",
    "dynamic": "ダイナミック",
    "variable": "バリアブル",
    "constant": "コンスタント",
    "protocol": "プロトコル",
    "regex": "レゲックス",
    "unicode": "ユニコード",
    "encrypt": "エンクリプト",
    "decrypt": "デクリプト",
    "compress": "コンプレス",
    "certificate": "サーティフィケート",
    "cookie": "クッキー",
    "jwt": "ジェイダブリューティー",
    "oauth": "オーオース",
    "sql": "エスキューエル",
    "nosql": "ノーエスキューエル",
    "redis": "レディス",
    "sqlite": "エスキューライト",
    "orm": "オーアールエム",
    "crud": "クラッド",
    "system": "システム",
    "home": "ホーム",
    "root": "ルート",
    "admin": "アドミン",
    "access": "アクセス",
    "permission": "パーミッション",
}

try:
    import fugashi as _fugashi_mod
    _tagger = _fugashi_mod.Tagger()
except Exception:
    _tagger = None


def _word_to_kana(word: str) -> str:
    lower = word.lower()
    if lower in _EN_KANA:
        return _EN_KANA[lower]
    if _tagger is not None:
        try:
            tokens = list(_tagger(word))
            if len(tokens) == 1:
                pron = getattr(tokens[0].feature, "pron", "*")
                if pron and pron != "*":
                    return pron
        except Exception:
            pass
    return word


def romanize_english(text: str) -> str:
    return re.sub(r"[A-Za-z][A-Za-z0-9]*", lambda m: _word_to_kana(m.group()), text)


# ─────────────────────────────────────────────────────────────────────────────


def get_auth() -> tuple[str, str] | None:
    load_dotenv(Path.home() / ".claude" / ".env")
    auth_str = os.environ.get("VOISONA_AUTH", "")
    if ":" in auth_str:
        user, _, password = auth_str.partition(":")
        return (user, password)
    return None


def _content_to_text(content: object) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(
            block.get("text", "")
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        )
    return ""


def _load_state() -> dict:
    try:
        return json.loads(_STATE_FILE.read_text("utf-8"))
    except Exception:
        return {}


def _save_state(state: dict) -> None:
    try:
        _STATE_FILE.write_text(json.dumps(state), "utf-8")
    except Exception:
        pass


def _find_transcript(session_id: str) -> str | None:
    projects = Path.home() / ".claude" / "projects"
    if projects.exists():
        hits = list(projects.rglob(f"{session_id}.jsonl"))
        if hits:
            return str(hits[0])
    return None


def _is_tool_result(entry: dict) -> bool:
    content = entry.get("message", {}).get("content", "")
    if not isinstance(content, list) or not content:
        return False
    return all(isinstance(b, dict) and b.get("type") == "tool_result" for b in content)


def get_new_texts(transcript_path: str, after_idx: int) -> tuple[list[str], int]:
    """Return (texts, new_last_idx) for assistant text entries added after after_idx."""
    try:
        raw = Path(transcript_path).read_bytes().decode("utf-8", errors="replace")
        entries: list[dict | None] = []
        for line in raw.splitlines():
            if not line.strip():
                continue
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                entries.append(None)

        # Find last human user message as minimum start boundary
        last_human_idx = -1
        for i, entry in enumerate(entries):
            if entry and entry.get("type") == "user" and not _is_tool_result(entry):
                last_human_idx = i

        start = max(last_human_idx, after_idx)
        texts: list[str] = []
        last_processed = start
        for i in range(start + 1, len(entries)):
            entry = entries[i]
            last_processed = i
            if entry and entry.get("type") == "assistant":
                t = _content_to_text(entry.get("message", {}).get("content", ""))
                if t.strip():
                    texts.append(t)

        return texts, last_processed
    except Exception:
        return [], after_idx


def _inline_code_to_text(m: re.Match) -> str:
    inner = m.group()[1:-1]
    inner = re.sub(r"[_.\-/\\:,;()\[\]{}]", " ", inner)
    inner = re.sub(r"[^\w\s]", "", inner)
    return re.sub(r"\s+", " ", inner).strip()


def clean_text(text: str) -> str:
    text = re.sub(r"```[\s\S]*?```", "（コードは省略）", text)
    text = re.sub(r"`[^`\n]+`", _inline_code_to_text, text)
    text = re.sub(r"!\[[^\]]*\]\([^)]+\)", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"\*{1,3}([^*\n]+)\*{1,3}", r"\1", text)
    text = re.sub(r"^#{1,6}\s+", "", text, flags=re.MULTILINE)
    text = re.sub(r"^[-*_]{3,}\s*$", "", text, flags=re.MULTILINE)
    text = re.sub(r"^[-*+]\s+", "", text, flags=re.MULTILINE)
    text = re.sub(r"^\d+\.\s+", "", text, flags=re.MULTILINE)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def split_chunks(text: str) -> list[str]:
    sentences = re.split(r"(?<=[。！？!?])\s*", text)
    chunks: list[str] = []
    current = ""
    for sent in sentences:
        if not sent.strip():
            continue
        if len(current) + len(sent) <= MAX_TEXT_LEN:
            current += sent
        else:
            if current:
                chunks.append(current)
            if len(sent) > MAX_TEXT_LEN:
                for i in range(0, len(sent), MAX_TEXT_LEN):
                    chunks.append(sent[i : i + MAX_TEXT_LEN])
                current = ""
            else:
                current = sent
    if current:
        chunks.append(current)
    return chunks


def speak(text: str, auth: tuple[str, str] | None) -> None:
    try:
        resp = requests.post(
            f"{BASE_URL}/speech-syntheses",
            json={
                "language": LANGUAGE,
                "text": text,
                "destination": "audio_device",
                "force_enqueue": True,
            },
            auth=auth,
            timeout=10,
        )
        resp.raise_for_status()
        uuid = resp.json().get("uuid")
        if not uuid:
            return

        deadline = time.monotonic() + POLL_TIMEOUT
        while time.monotonic() < deadline:
            time.sleep(POLL_INTERVAL)
            poll = requests.get(
                f"{BASE_URL}/speech-syntheses/{uuid}",
                auth=auth,
                timeout=10,
            )
            poll.raise_for_status()
            state = poll.json().get("state", "")
            if state in ("succeeded", "failed", "cancelled"):
                break
    except Exception:
        pass


def _speak_texts(texts: list[str], auth: tuple[str, str] | None) -> None:
    combined = clean_text("\n".join(texts))
    if not combined:
        return
    combined = romanize_english(combined)
    for chunk in split_chunks(combined):
        speak(chunk, auth)


def main() -> None:
    raw = sys.stdin.buffer.read()
    if not raw.strip():
        return

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return

    # Stop hook: stop_hook_active guard
    if data.get("stop_hook_active"):
        return

    session_id = data.get("session_id", "")
    is_stop = "stop_hook_active" in data  # key presence = Stop hook

    transcript_path = data.get("transcript_path") or _find_transcript(session_id)

    state = _load_state()
    if state.get("session_id") != session_id:
        state = {"session_id": session_id, "last_idx": -1}

    after_idx: int = state.get("last_idx", -1)

    if transcript_path:
        texts, new_last_idx = get_new_texts(transcript_path, after_idx)
    else:
        # Fallback: use last_assistant_message from Stop hook data
        texts = [_content_to_text(data.get("last_assistant_message", ""))]
        new_last_idx = after_idx

    if is_stop:
        _save_state({})
    else:
        state["last_idx"] = new_last_idx
        _save_state(state)

    if texts:
        _speak_texts([t for t in texts if t.strip()], get_auth())


if __name__ == "__main__":
    main()
