#!/usr/bin/env bash
set -euo pipefail

# Render a mermaid diagram to PNG and display inline.
# Supports iTerm2 (imgcat) and Ghostty (kitten icat).
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

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="${INPUT%.mmd}.png"
fi

MMDC_ARGS=(-i "$INPUT" -o "$OUTPUT" -t "$THEME" -w "$WIDTH" -b "$BG")
if [[ -n "$CSS" ]]; then
    MMDC_ARGS+=(-C "$CSS")
fi

if mmdc "${MMDC_ARGS[@]}" 2>&1; then
    echo "Rendered: $OUTPUT"

    # Detect terminal and build the display command
    VIEW_CMD=""
    case "${TERM_PROGRAM:-}" in
        iTerm.app)
            if command -v imgcat &>/dev/null; then
                VIEW_CMD="imgcat $OUTPUT"
            else
                VIEW_CMD="open $OUTPUT"
                echo "Note: imgcat not found. Install iTerm2 shell integration for inline display." >&2
            fi
            ;;
        ghostty)
            if command -v kitten &>/dev/null; then
                VIEW_CMD="kitten icat $OUTPUT"
            else
                VIEW_CMD="open $OUTPUT"
                echo "Note: kitten not found. Install kitty CLI tools for inline display." >&2
            fi
            ;;
        *)
            VIEW_CMD="open $OUTPUT"
            ;;
    esac

    # TODO: Claude Code's Bash tool captures stdout, so inline image escape
    # sequences (iTerm2 imgcat, Kitty graphics protocol) never reach the terminal.
    # Once Claude Code supports graphics passthrough, we can display directly.
    # Tracking: https://github.com/anthropics/claude-code/issues/29254
    echo "View: $VIEW_CMD"
else
    echo "Error: mmdc failed to render diagram" >&2
    exit 1
fi
