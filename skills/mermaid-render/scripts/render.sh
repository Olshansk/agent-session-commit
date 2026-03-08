#!/usr/bin/env bash
set -euo pipefail

# Render a mermaid diagram to PNG and display inline via iTerm2's imgcat.
#
# Usage: render.sh <input.mmd> [--theme <name>] [--width <px>] [--bg <color>] [--css <path>] [--output <path>]

INPUT=""
THEME="default"
WIDTH="1200"
BG="transparent"
CSS=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --theme)  THEME="$2";  shift 2 ;;
        --width)  WIDTH="$2";  shift 2 ;;
        --bg)     BG="$2";     shift 2 ;;
        --css)    CSS="$2";    shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        -*)       echo "Unknown flag: $1" >&2; exit 1 ;;
        *)        INPUT="$1";  shift ;;
    esac
done

if [[ -z "$INPUT" ]]; then
    echo "Usage: render.sh <input.mmd> [options]" >&2
    exit 1
fi

if [[ ! -f "$INPUT" ]]; then
    echo "Error: File not found: $INPUT" >&2
    exit 1
fi

if ! command -v mmdc &>/dev/null; then
    echo "Error: mmdc not found. Install with: npm install -g @mermaid-js/mermaid-cli" >&2
    exit 1
fi

if ! command -v imgcat &>/dev/null; then
    echo "Error: imgcat not found. Install iTerm2 shell integration." >&2
    exit 1
fi

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="${INPUT%.mmd}.png"
fi

MMDC_ARGS=(-i "$INPUT" -o "$OUTPUT" -t "$THEME" -w "$WIDTH" -b "$BG")
if [[ -n "$CSS" ]]; then
    MMDC_ARGS+=(-C "$CSS")
fi

if mmdc "${MMDC_ARGS[@]}" 2>&1; then
    imgcat "$OUTPUT"
else
    echo "Error: mmdc failed to render diagram" >&2
    exit 1
fi
