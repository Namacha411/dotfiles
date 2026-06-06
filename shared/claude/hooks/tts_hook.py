# /// script
# dependencies = [
#   "requests>=2.31",
#   "fugashi[unidic-lite]",
# ]
# requires-python = ">=3.9"
# ///

from __future__ import annotations

import argparse
import dataclasses
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path

import requests

BASE_URL = "http://localhost:32766/api/talk/v1"

_STATE_FILE = Path(os.environ.get("TEMP", str(Path.home()))) / "tts_hook_state.json"
_CONFIG_FILE = Path.home() / ".claude" / "hooks" / "tts_config.json"


# ── Config ────────────────────────────────────────────────────────────────────


@dataclass
class Config:
    language: str = "ja_JP"
    voice_name: str | None = None
    voice_version: str | None = None
    auth: str | None = None  # "user:password"
    max_text_len: int = 500
    poll_interval: float = 0.5
    poll_timeout: float = 60.0


def _load_config() -> Config:
    try:
        data = json.loads(_CONFIG_FILE.read_text("utf-8"))
        known = {f.name for f in dataclasses.fields(Config)}
        return Config(**{k: v for k, v in data.items() if k in known})
    except Exception:
        return Config()


def _save_config(cfg: Config) -> None:
    _CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
    _CONFIG_FILE.write_text(
        json.dumps(dataclasses.asdict(cfg), indent=2, ensure_ascii=False) + "\n",
        "utf-8",
    )


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


def _split_camel_case(word: str) -> list[str]:
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", word)
    s = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1 \2", s)
    return s.split()


def _word_to_kana(word: str) -> str:
    lower = word.lower()
    if lower in _EN_KANA:
        return _EN_KANA[lower]
    parts = _split_camel_case(word)
    if len(parts) > 1:
        return "".join(_word_to_kana(p) for p in parts)
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


# ── Auth ──────────────────────────────────────────────────────────────────────


def get_auth(cfg: Config) -> tuple[str, str] | None:
    auth_str = cfg.auth or os.environ.get("VOISONA_AUTH", "")
    if ":" in auth_str:
        user, _, password = auth_str.partition(":")
        return (user, password)
    return None


# ── Transcript helpers ────────────────────────────────────────────────────────


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


# ── Text processing ───────────────────────────────────────────────────────────


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


# Boundary patterns ordered from coarsest to finest
_SPLIT_BOUNDARIES = [
    r"(?<=[。！？!?])\s*",  # sentence
    r"(?<=[、,])\s*",        # clause
    r"\s+",                  # word
]


def split_chunks(text: str, max_len: int) -> list[str]:
    def _merge(parts: list[str], level: int) -> list[str]:
        chunks: list[str] = []
        current = ""
        for part in parts:
            if not part.strip():
                continue
            if len(current) + len(part) <= max_len:
                current += part
            else:
                if current:
                    chunks.append(current)
                if len(part) > max_len:
                    chunks.extend(_split(part, level + 1))
                    current = ""
                else:
                    current = part
        if current:
            chunks.append(current)
        return chunks

    def _split(segment: str, level: int) -> list[str]:
        if len(segment) <= max_len:
            return [segment] if segment.strip() else []
        if level < len(_SPLIT_BOUNDARIES):
            parts = re.split(_SPLIT_BOUNDARIES[level], segment)
            if len(parts) > 1:
                return _merge(parts, level)
        # hard split as last resort
        return [segment[i : i + max_len] for i in range(0, len(segment), max_len)]

    return _split(text, 0)


# ── Speak ─────────────────────────────────────────────────────────────────────


def speak(text: str, auth: tuple[str, str] | None, cfg: Config) -> None:
    try:
        body: dict = {
            "language": cfg.language,
            "text": text,
            "destination": "audio_device",
            "force_enqueue": True,
        }
        if cfg.voice_name is not None:
            body["voice_name"] = cfg.voice_name
        if cfg.voice_version is not None:
            body["voice_version"] = cfg.voice_version

        resp = requests.post(
            f"{BASE_URL}/speech-syntheses",
            json=body,
            auth=auth,
            timeout=10,
        )
        resp.raise_for_status()
        uuid = resp.json().get("uuid")
        if not uuid:
            return

        deadline = time.monotonic() + cfg.poll_timeout
        while time.monotonic() < deadline:
            time.sleep(cfg.poll_interval)
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


def _speak_texts(texts: list[str], auth: tuple[str, str] | None, cfg: Config) -> None:
    combined = clean_text("\n".join(texts))
    if not combined:
        return
    if cfg.language == "ja_JP":
        combined = romanize_english(combined)
    for chunk in split_chunks(combined, cfg.max_text_len):
        speak(chunk, auth, cfg)


# ── CLI subcommands ───────────────────────────────────────────────────────────


def _cmd_init(args: argparse.Namespace) -> None:
    if _CONFIG_FILE.exists() and not args.force:
        print(f"Config already exists: {_CONFIG_FILE}")
        print("Use --force to overwrite.")
        return
    _save_config(Config())
    print(f"Created: {_CONFIG_FILE}")
    _cmd_show(args)


def _cmd_show(_args: argparse.Namespace) -> None:
    cfg = _load_config()
    d = dataclasses.asdict(cfg)
    if d.get("auth"):
        user, _, _ = d["auth"].partition(":")
        d["auth"] = f"{user}:****"
    print(json.dumps(d, indent=2, ensure_ascii=False))


def _cmd_set(args: argparse.Namespace) -> None:
    valid = {f.name for f in dataclasses.fields(Config)}
    if args.key not in valid:
        print(f"Unknown key: {args.key!r}")
        print(f"Valid keys: {', '.join(sorted(valid))}")
        sys.exit(1)

    cfg = _load_config()
    raw = args.value

    if raw.lower() == "null":
        value: object = None
    else:
        # Determine target type from the default value
        defaults = dataclasses.asdict(Config())
        default = defaults[args.key]
        if isinstance(default, bool):
            value = raw.lower() in ("true", "1", "yes")
        elif isinstance(default, int):
            value = int(raw)
        elif isinstance(default, float):
            value = float(raw)
        else:
            value = raw

    setattr(cfg, args.key, value)
    _save_config(cfg)
    print(f"Set {args.key} = {value!r}")


def _fetch_voices(cfg: Config) -> list[dict]:
    resp = requests.get(f"{BASE_URL}/voices", auth=get_auth(cfg), timeout=10)
    resp.raise_for_status()
    return resp.json().get("items", [])


def _format_voice_line(v: dict, current_name: str | None, index: int) -> str:
    name_ja = next((d["name"] for d in v["display_names"] if d["language"] == "ja_JP"), None)
    name_en = next((d["name"] for d in v["display_names"] if d["language"] == "en_US"), None)
    display = name_ja or name_en or v["voice_name"]
    alt = f" ({name_en})" if name_ja and name_en else ""
    langs = ", ".join(v.get("languages", []))
    marker = " ← current" if v["voice_name"] == current_name else ""
    return f"  {index}. {display}{alt}  [{langs}]  {v['voice_name']} v{v['voice_version']}{marker}"


def _cmd_voices(_args: argparse.Namespace) -> None:
    cfg = _load_config()
    try:
        voices = _fetch_voices(cfg)
    except Exception as e:
        print(f"Failed to fetch voices: {e}")
        sys.exit(1)
    if not voices:
        print("No voices found.")
        return
    for i, v in enumerate(voices, 1):
        print(_format_voice_line(v, cfg.voice_name, i))


def _cmd_pick(_args: argparse.Namespace) -> None:
    cfg = _load_config()
    try:
        voices = _fetch_voices(cfg)
    except Exception as e:
        print(f"Failed to fetch voices: {e}")
        sys.exit(1)
    if not voices:
        print("No voices found.")
        return

    print("Available voices:\n")
    for i, v in enumerate(voices, 1):
        print(_format_voice_line(v, cfg.voice_name, i))
    print()

    current_info = cfg.voice_name or "none"
    try:
        raw = input(f"Select (1-{len(voices)}, Enter to keep [{current_info}]): ").strip()
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
        return

    if not raw:
        print("No change.")
        return

    try:
        idx = int(raw) - 1
        if not (0 <= idx < len(voices)):
            raise ValueError
    except ValueError:
        print(f"Invalid selection: {raw!r}")
        sys.exit(1)

    voice = voices[idx]
    cfg.voice_name = voice["voice_name"]
    cfg.voice_version = voice["voice_version"]
    _save_config(cfg)
    print(f"Set voice_name    = {cfg.voice_name!r}")
    print(f"Set voice_version = {cfg.voice_version!r}")


def _run_cli() -> None:
    parser = argparse.ArgumentParser(
        prog="tts_hook",
        description="TTS hook — config manager",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_init = sub.add_parser("init", help="Create default config file")
    p_init.add_argument("--force", action="store_true", help="Overwrite existing config")

    sub.add_parser("show", help="Show current config (password masked)")

    p_set = sub.add_parser("set", help="Set a config value")
    p_set.add_argument("key", help="Config key")
    p_set.add_argument("value", help="New value (use 'null' to clear optional fields)")

    sub.add_parser("voices", help="List available voices from the API")
    sub.add_parser("pick", help="Interactively select a voice and save to config")

    args = parser.parse_args()
    {
        "init": _cmd_init,
        "show": _cmd_show,
        "set": _cmd_set,
        "voices": _cmd_voices,
        "pick": _cmd_pick,
    }[args.cmd](args)


# ── Hook entry point ──────────────────────────────────────────────────────────


def _run_hook() -> None:
    raw = sys.stdin.buffer.read()
    if not raw.strip():
        return

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return

    if data.get("stop_hook_active"):
        return

    if "stop_hook_active" in data:
        _save_state({})
        return

    cfg = _load_config()
    auth = get_auth(cfg)

    msg = data.get("message")
    if isinstance(msg, dict) and msg.get("role") == "assistant":
        text = _content_to_text(msg.get("content", ""))
        if text.strip():
            _speak_texts([text], auth, cfg)
        return

    session_id = data.get("session_id", "")
    transcript_path = data.get("transcript_path") or _find_transcript(session_id)

    state = _load_state()
    if state.get("session_id") != session_id:
        state = {"session_id": session_id, "last_idx": -1}

    after_idx: int = state.get("last_idx", -1)

    if transcript_path:
        texts, new_last_idx = get_new_texts(transcript_path, after_idx)
        state["last_idx"] = new_last_idx
        _save_state(state)
        if texts:
            _speak_texts([t for t in texts if t.strip()], auth, cfg)
    else:
        text = _content_to_text(data.get("last_assistant_message", ""))
        if text.strip():
            _speak_texts([text], auth, cfg)


def main() -> None:
    if len(sys.argv) > 1:
        _run_cli()
    else:
        _run_hook()


if __name__ == "__main__":
    main()
