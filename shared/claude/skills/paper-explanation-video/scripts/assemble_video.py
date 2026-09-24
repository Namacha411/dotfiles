#!/usr/bin/env python3
# /// script
# dependencies = []
# requires-python = ">=3.12"
# ///
"""Assemble a narrated slide deck (image + wav per segment) into one mp4.

For each segment, loops the still image for exactly as long as its narration
audio (ffmpeg's -shortest against the audio stream), then concatenates all
segment clips back-to-back with the ffmpeg concat demuxer.

Usage:
    uv run assemble_video.py --manifest manifest.json --output final.mp4
    uv run assemble_video.py --output final.mp4 \
        --pair slides/01.png audio/01.wav \
        --pair slides/02.png audio/02.wav

manifest.json format:
    [
      {"image": "slides/01.png", "audio": "audio/01.wav"},
      {"image": "slides/02.png", "audio": "audio/02.wav"}
    ]

Requires ffmpeg on PATH.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile


def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"Command failed: {' '.join(cmd)}\n{result.stderr}")
    return result


def build_segment(image_path, audio_path, out_path, resolution):
    width, height = resolution
    run([
        "ffmpeg", "-y",
        "-loop", "1", "-i", image_path,
        "-i", audio_path,
        "-c:v", "libx264", "-tune", "stillimage",
        "-c:a", "aac", "-b:a", "192k",
        "-pix_fmt", "yuv420p",
        "-vf", f"scale={width}:{height}",
        "-shortest",
        out_path,
    ])


def concat_segments(segment_paths, out_path, work_dir):
    list_path = os.path.join(work_dir, "concat_list.txt")
    with open(list_path, "w", encoding="utf-8") as f:
        for p in segment_paths:
            escaped = os.path.abspath(p).replace("'", "'\\''")
            f.write(f"file '{escaped}'\n")
    run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", list_path, "-c", "copy", out_path])


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--manifest", help="JSON file listing [{image, audio}, ...] in order")
    parser.add_argument("--pair", nargs=2, action="append", metavar=("IMAGE", "AUDIO"),
                         help="Add one (image, audio) segment; repeat in order. Alternative to --manifest.")
    parser.add_argument("--output", required=True, help="Final mp4 path")
    parser.add_argument("--width", type=int, default=1920)
    parser.add_argument("--height", type=int, default=1080)
    args = parser.parse_args()

    if shutil.which("ffmpeg") is None:
        sys.exit("ffmpeg not found on PATH.")

    segments = []
    if args.manifest:
        with open(args.manifest, encoding="utf-8") as f:
            segments = json.load(f)
    if args.pair:
        segments += [{"image": img, "audio": aud} for img, aud in args.pair]
    if not segments:
        sys.exit("Provide --manifest or at least one --pair")

    with tempfile.TemporaryDirectory(prefix="paper-explanation-video-") as work_dir:
        segment_paths = []
        for i, seg in enumerate(segments):
            out_path = os.path.join(work_dir, f"segment-{i:03d}.mp4")
            build_segment(seg["image"], seg["audio"], out_path, (args.width, args.height))
            segment_paths.append(out_path)

        os.makedirs(os.path.dirname(os.path.abspath(args.output)) or ".", exist_ok=True)
        concat_segments(segment_paths, args.output, work_dir)

    print(json.dumps({"output": os.path.abspath(args.output), "segments": len(segments)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
