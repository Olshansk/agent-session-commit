#!/usr/bin/env python3
"""Regenerate the 3rd-party skills table in README.md from ~/.agents/skills/.

Skips any skill whose name also exists in this repo's skills/ directory
(those are authored here and shown in the other tables).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
REPO_SKILLS = REPO_ROOT / "skills"
THIRDPARTY_SKILLS = Path.home() / ".agents" / "skills"
README = REPO_ROOT / "README.md"

BEGIN_MARKER = "<!-- BEGIN: 3rd-party-skills -->"
END_MARKER = "<!-- END: 3rd-party-skills -->"


def parse_frontmatter(skill_md: Path) -> dict[str, str]:
    """Minimal YAML frontmatter parser: handles plain scalars and folded `>-` blocks."""
    text = skill_md.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return {}
    _, fm, *_ = text.split("---", 2)
    out: dict[str, str] = {}
    lines = fm.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"^([a-zA-Z_-]+):\s*(.*)$", line)
        if not m:
            i += 1
            continue
        key, value = m.group(1), m.group(2).strip()
        if value in (">-", ">", "|", "|-", ""):
            i += 1
            chunks: list[str] = []
            while i < len(lines) and (lines[i].startswith(("  ", "\t")) or lines[i].strip() == ""):
                chunks.append(lines[i].strip())
                i += 1
            joined = " ".join(c for c in chunks if c)
            out[key] = joined if joined or value else value
        else:
            out[key] = value.strip('"').strip("'")
            i += 1
    return out


def collect_third_party() -> list[tuple[str, str]]:
    repo_names = {p.name for p in REPO_SKILLS.iterdir() if p.is_dir()}
    rows: list[tuple[str, str]] = []
    if not THIRDPARTY_SKILLS.is_dir():
        return rows
    for skill_dir in sorted(THIRDPARTY_SKILLS.iterdir()):
        if not skill_dir.is_dir() or skill_dir.name in repo_names:
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.is_file():
            continue
        fm = parse_frontmatter(skill_md)
        name = fm.get("name", skill_dir.name)
        desc = fm.get("description", "").replace("|", "\\|").replace("\n", " ").strip()
        rows.append((name, desc))
    return rows


def render_table(rows: list[tuple[str, str]]) -> str:
    lines = ["| Skill | Description |", "| ----- | ----------- |"]
    for name, desc in rows:
        lines.append(f"| `{name}` | {desc} |")
    return "\n".join(lines)


def replace_block(content: str, table: str) -> str:
    pattern = re.compile(
        re.escape(BEGIN_MARKER) + r".*?" + re.escape(END_MARKER),
        re.DOTALL,
    )
    block = f"{BEGIN_MARKER}\n\n{table}\n\n{END_MARKER}"
    if not pattern.search(content):
        raise SystemExit(
            f"markers not found in {README}. Add {BEGIN_MARKER} and {END_MARKER} first."
        )
    return pattern.sub(block, content)


def main() -> int:
    rows = collect_third_party()
    table = render_table(rows)
    original = README.read_text(encoding="utf-8")
    updated = replace_block(original, table)
    if updated != original:
        README.write_text(updated, encoding="utf-8")
        print(f"Updated {README} with {len(rows)} 3rd-party skill(s)")
    else:
        print(f"No changes — {len(rows)} 3rd-party skill(s) already in sync")
    return 0


if __name__ == "__main__":
    sys.exit(main())
