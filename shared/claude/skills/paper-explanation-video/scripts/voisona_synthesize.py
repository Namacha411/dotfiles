#!/usr/bin/env python3
# /// script
# dependencies = []
# requires-python = ">=3.12"
# ///
"""CLI wrapper around the VoiSona Talk local speech-synthesis API.

Submits a POST /speech-syntheses request, polls GET /speech-syntheses/{uuid}
until it reaches "succeeded", and prints the resulting file path + duration
as JSON. Also supports listing available voices/languages for discovery.

Auth: reads VOISONA_TALK_USER / VOISONA_TALK_PASSWORD from the environment.
Never hardcode credentials here or pass them on the command line.

Examples:
    uv run voisona_synthesize.py list-voices
    uv run voisona_synthesize.py synthesize --text "こんにちは" --language ja_JP \
        --voice-name tanaka-san_ja_JP --voice-version 2.0.1 --output out/segment01.wav
"""
import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

DEFAULT_BASE_URL = "http://localhost:32766/api/talk/v1"
# POST /speech-syntheses rejects `text` longer than this (see references/voisona-talk-api.md)
MAX_TEXT_CHARS = 500


def _auth_header():
    user = os.environ.get("VOISONA_TALK_USER")
    password = os.environ.get("VOISONA_TALK_PASSWORD")
    if not user or not password:
        sys.exit(
            "VOISONA_TALK_USER / VOISONA_TALK_PASSWORD environment variables must be set "
            "(configured in the VoiSona Talk editor's API settings)."
        )
    token = base64.b64encode(f"{user}:{password}".encode()).decode()
    return f"Basic {token}"


def _request(method, url, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", _auth_header())
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw.decode()) if raw else {})
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        sys.exit(f"{method} {url} -> HTTP {e.code}: {detail}")


def synthesize(base_url, text, language, output_path, voice_name=None, voice_version=None,
               speed=None, pitch=None, intonation=None, volume=None,
               poll_interval=0.5, timeout=120):
    output_path = os.path.abspath(output_path)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    body = {
        "text": text,
        "language": language,
        "destination": "file",
        "output_file_path": output_path,
        "can_overwrite_file": True,
        "force_enqueue": True,
    }
    if voice_name:
        body["voice_name"] = voice_name
    if voice_version:
        body["voice_version"] = voice_version
    global_parameters = {
        k: v for k, v in {
            "speed": speed, "pitch": pitch, "intonation": intonation, "volume": volume,
        }.items() if v is not None
    }
    if global_parameters:
        body["global_parameters"] = global_parameters

    _, created = _request("POST", f"{base_url}/speech-syntheses", body)
    request_uuid = created["uuid"]

    deadline = time.time() + timeout
    while True:
        _, info = _request("GET", f"{base_url}/speech-syntheses/{request_uuid}")
        state = info.get("state")
        if state == "succeeded":
            return info
        if state not in ("queued", "running"):
            sys.exit(f"speech synthesis {request_uuid} ended in unexpected state: {info}")
        if time.time() > deadline:
            sys.exit(f"speech synthesis {request_uuid} timed out after {timeout}s (last state: {state})")
        time.sleep(poll_interval)


def cmd_synthesize(args):
    text = args.text
    if args.text_file:
        with open(args.text_file, encoding="utf-8") as f:
            text = f.read().strip()
    if not text:
        sys.exit("Provide --text or --text-file")
    if len(text) > MAX_TEXT_CHARS:
        sys.exit(
            f"text is {len(text)} chars; the API accepts at most {MAX_TEXT_CHARS}. "
            "Split this segment into shorter ones."
        )

    info = synthesize(
        args.base_url, text, args.language, args.output,
        voice_name=args.voice_name, voice_version=args.voice_version,
        speed=args.speed, pitch=args.pitch, intonation=args.intonation, volume=args.volume,
        timeout=args.timeout,
    )
    print(json.dumps({
        "output_file_path": os.path.abspath(args.output),
        "duration": info.get("duration"),
    }, ensure_ascii=False))


def cmd_list_voices(args):
    _, data = _request("GET", f"{args.base_url}/voices")
    print(json.dumps(data, ensure_ascii=False, indent=2))


def cmd_list_languages(args):
    _, data = _request("GET", f"{args.base_url}/languages")
    print(json.dumps(data, ensure_ascii=False, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    sub = parser.add_subparsers(dest="command", required=True)

    p_synth = sub.add_parser("synthesize", help="Synthesize one narration segment to a WAV file")
    p_synth.add_argument("--text", help="Text to synthesize")
    p_synth.add_argument("--text-file", help="Read text from this file instead of --text")
    p_synth.add_argument("--language", default="ja_JP")
    p_synth.add_argument("--output", required=True, help="Output WAV path")
    p_synth.add_argument("--voice-name")
    p_synth.add_argument("--voice-version")
    p_synth.add_argument("--speed", type=float, help="1.0 = normal")
    p_synth.add_argument("--pitch", type=float, help="0.0 = normal")
    p_synth.add_argument("--intonation", type=float, help="1.0 = normal")
    p_synth.add_argument("--volume", type=float, help="0.0 = normal")
    p_synth.add_argument("--timeout", type=float, default=120)
    p_synth.set_defaults(func=cmd_synthesize)

    p_voices = sub.add_parser("list-voices", help="List available voice libraries")
    p_voices.set_defaults(func=cmd_list_voices)

    p_langs = sub.add_parser("list-languages", help="List supported languages")
    p_langs.set_defaults(func=cmd_list_languages)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
