#!/usr/bin/env python3
"""
Scrape skills.sh and generate an interactive HTML dashboard.

Usage:
    python3 scrape_and_build.py
    python3 scrape_and_build.py --output /path/to/dashboard.html
    python3 scrape_and_build.py --json  # also dump raw JSON
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from collections import defaultdict
from datetime import date
from pathlib import Path

CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "skills-dashboard"
CACHE_FILE = CACHE_DIR / "skills_cache.json"
CACHE_MAX_AGE_HOURS = 1


API_BASE = "https://skills.sh/api/search"
# Broad 2-char queries that collectively cover ~99%+ of all skills.
# Ordered by yield (most new results first) to minimize wasted requests.
SEARCH_QUERIES = [
    "sk", "in", "er", "re", "an", "es", "ai", "co", "th", "or",
    "on", "ti", "at", "en", "de", "ou", "it", "is", "al", "ar",
    "st", "le", "ng", "io", "us", "ab", "op", "gu", "hy", "ux",
    "ex", "ph", "qu", "zy", "mu", "py", "go", "ja", "sw", "wo",
]
QUERY_PAUSE_SECONDS = 0.2


def _fetch_query(query: str, limit: int = 100_000, retries: int = 3) -> list[dict]:
    """Fetch skills matching a search query from the skills.sh API."""
    url = f"{API_BASE}?q={query}&limit={limit}"
    req = urllib.request.Request(url, headers={"User-Agent": "skills-dashboard/1.0"})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            return data.get("skills", [])
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
            retry_after = e.headers.get("Retry-After")
            if retry_after is not None:
                try:
                    wait = max(1, int(retry_after))
                except ValueError:
                    wait = 2 ** attempt
            else:
                wait = 2 ** attempt
            if attempt < retries - 1:
                print(f"    Retry {attempt + 1}/{retries} for q={query} ({e}), waiting {wait}s...")
                time.sleep(wait)
            else:
                print(f"    Skipping q={query} after repeated rate limits ({e}).")
                return []
        except (urllib.error.URLError, TimeoutError) as e:
            if attempt < retries - 1:
                wait = 2 ** attempt
                print(f"    Retry {attempt + 1}/{retries} for q={query} ({e}), waiting {wait}s...")
                time.sleep(wait)
            else:
                raise


def _load_cache() -> list[dict] | None:
    """Load skills from cache if it exists and is fresh."""
    if not CACHE_FILE.exists():
        return None
    try:
        data = json.loads(CACHE_FILE.read_text())
        age_hours = (time.time() - data["timestamp"]) / 3600
        if age_hours > CACHE_MAX_AGE_HOURS:
            print(f"Cache expired ({age_hours:.1f}h old, max {CACHE_MAX_AGE_HOURS}h). Re-fetching...")
            return None
        print(f"Using cached data ({age_hours:.0f}m old, {len(data['skills']):,} skills)")
        return data["skills"]
    except (json.JSONDecodeError, KeyError):
        return None


def _save_cache(skills: list[dict]) -> None:
    """Save skills to cache."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_FILE.write_text(json.dumps({"timestamp": time.time(), "skills": skills}))
    print(f"Cached to {CACHE_FILE}")


def _fetch_from_api() -> list[dict]:
    """Fetch all skills from skills.sh via the search API."""
    all_skills: dict[str, dict] = {}
    print("Fetching skills from skills.sh API...")
    for index, q in enumerate(SEARCH_QUERIES):
        batch = _fetch_query(q)
        before = len(all_skills)
        for s in batch:
            all_skills[s["id"]] = s
        added = len(all_skills) - before
        if added > 0:
            print(f"  q={q:4s}: +{added:>5,} -> {len(all_skills):>6,} unique skills")
        if index < len(SEARCH_QUERIES) - 1:
            time.sleep(QUERY_PAUSE_SECONDS)
    skills = sorted(all_skills.values(), key=lambda s: s["installs"], reverse=True)
    print(f"Total: {len(skills):,} unique skills")
    return skills


def fetch_skills(no_cache: bool = False) -> list[dict]:
    """Fetch all skills, using cache unless --no-cache is set."""
    if not no_cache:
        cached = _load_cache()
        if cached is not None:
            return cached
    skills = _fetch_from_api()
    _save_cache(skills)
    return skills


def aggregate(skills: list[dict]) -> list[dict]:
    """Aggregate skills by owner (GitHub org/user)."""
    owners = defaultdict(lambda: {"count": 0, "total_installs": 0, "skills": [], "repos": set()})
    for s in skills:
        owner = s["source"].split("/")[0]
        owners[owner]["count"] += 1
        owners[owner]["total_installs"] += s["installs"]
        owners[owner]["skills"].append(
            {"name": s["name"], "installs": s["installs"], "repo": s["source"]}
        )
        owners[owner]["repos"].add(s["source"])

    result = []
    for owner, data in sorted(owners.items(), key=lambda x: x[1]["total_installs"], reverse=True):
        result.append(
            {
                "owner": owner,
                "count": data["count"],
                "total_installs": data["total_installs"],
                "repos": len(data["repos"]),
                "skills": sorted(data["skills"], key=lambda x: x["installs"], reverse=True),
            }
        )
    return result


def print_summary(skills: list[dict], owners: list[dict]):
    """Print a text summary to stdout."""
    total_installs = sum(s["installs"] for s in skills)
    print(f"\n{'='*60}")
    print(f"  Skills: {len(skills)}  |  Publishers: {len(owners)}  |  Installs: {total_installs:,}")
    print(f"{'='*60}")
    print("\nTop 10 publishers by installs:")
    for o in owners[:10]:
        print(f"  {o['total_installs']:>10,}  {o['count']:3d} skills  {o['owner']}")
    print(f"\nTop 10 publishers by skill count:")
    for o in sorted(owners, key=lambda x: x["count"], reverse=True)[:10]:
        print(f"  {o['count']:3d} skills  {o['total_installs']:>10,} installs  {o['owner']}")


def build_html(skills: list[dict], owners: list[dict]) -> str:
    """Generate the self-contained HTML dashboard."""
    # Only embed data needed for charts to keep HTML small:
    # - Top 50 skills (for top-30 bar + headroom)
    # - Top 50 owners (for bar charts + treemap)
    # - All install values (for histogram) as a flat array
    top_skills = skills[:50]
    top_owners = owners[:50]
    all_installs = [s["installs"] for s in skills]

    skills_json = json.dumps(top_skills)
    owner_json = json.dumps(top_owners)
    installs_json = json.dumps(all_installs)
    today = date.today().isoformat()
    total_installs = sum(s["installs"] for s in skills)
    total_installs_label = f"{total_installs / 1_000_000:.1f}M"

    return f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Skills.sh Ecosystem Dashboard</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
<script src="https://cdn.plot.ly/plotly-2.35.0.min.js"></script>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html {{ scroll-behavior: smooth; }}
  body {{
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
    background: #0a0a0f;
    color: #e0e0e0;
    min-height: 100vh;
    line-height: 1.6;
  }}
  .container {{
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 16px;
  }}

  /* Animations */
  @keyframes fadeInUp {{
    from {{ opacity: 0; transform: translateY(24px); }}
    to {{ opacity: 1; transform: translateY(0); }}
  }}
  @keyframes gradientShift {{
    0%, 100% {{ background-position: 0% 50%; }}
    50% {{ background-position: 100% 50%; }}
  }}
  @keyframes glowPulse {{
    0%, 100% {{ opacity: 0.4; transform: scale(1); }}
    50% {{ opacity: 0.7; transform: scale(1.05); }}
  }}
  .fade-in {{ animation: fadeInUp 0.6s ease-out both; }}
  .d1 {{ animation-delay: 0.05s; }}
  .d2 {{ animation-delay: 0.1s; }}
  .d3 {{ animation-delay: 0.15s; }}
  .d4 {{ animation-delay: 0.2s; }}
  .d5 {{ animation-delay: 0.25s; }}
  .d6 {{ animation-delay: 0.3s; }}
  .d7 {{ animation-delay: 0.35s; }}

  /* Sticky nav */
  .nav {{
    position: sticky;
    top: 0;
    z-index: 100;
    background: rgba(10, 10, 15, 0.75);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border-bottom: 1px solid rgba(124, 58, 237, 0.15);
    padding: 12px 0;
  }}
  .nav-inner {{
    max-width: 1400px;
    margin: 0 auto;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 24px;
  }}
  .nav-brand {{
    font-weight: 800;
    font-size: 1rem;
    background: linear-gradient(135deg, #7c3aed, #06b6d4);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }}
  .nav-links {{
    display: flex;
    gap: 24px;
    list-style: none;
  }}
  .nav-links a {{
    color: #888;
    text-decoration: none;
    font-size: 0.85rem;
    font-weight: 600;
    transition: color 0.2s;
  }}
  .nav-links a:hover {{ color: #c4b5fd; }}

  /* Header */
  .header {{
    text-align: center;
    padding: 60px 20px 24px;
    position: relative;
    overflow: hidden;
  }}
  .header::before {{
    content: '';
    position: absolute;
    top: -40%;
    left: 50%;
    transform: translateX(-50%);
    width: 600px;
    height: 600px;
    background: radial-gradient(circle, rgba(124, 58, 237, 0.12) 0%, transparent 70%);
    animation: glowPulse 8s ease-in-out infinite;
    pointer-events: none;
  }}
  .header h1 {{
    font-size: 2.8rem;
    font-weight: 800;
    background: linear-gradient(135deg, #7c3aed, #a78bfa, #06b6d4, #7c3aed);
    background-size: 200% 200%;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    animation: gradientShift 6s ease infinite;
    margin-bottom: 10px;
    position: relative;
  }}
  .header .tagline {{
    color: #888;
    font-size: 1.05rem;
    position: relative;
  }}

  /* Stat cards */
  .stats-row {{
    display: flex;
    justify-content: center;
    gap: 24px;
    padding: 24px 20px;
    flex-wrap: wrap;
  }}
  .stat {{
    text-align: center;
    background: rgba(124, 58, 237, 0.06);
    backdrop-filter: blur(10px);
    -webkit-backdrop-filter: blur(10px);
    border: 1px solid rgba(124, 58, 237, 0.15);
    border-radius: 16px;
    padding: 24px 32px;
    min-width: 160px;
    transition: transform 0.3s ease, box-shadow 0.3s ease, border-color 0.3s ease;
    position: relative;
    overflow: hidden;
  }}
  .stat::before {{
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 3px;
    background: linear-gradient(90deg, #7c3aed, #06b6d4);
    opacity: 0;
    transition: opacity 0.3s ease;
  }}
  .stat:hover {{
    transform: translateY(-4px);
    box-shadow: 0 8px 32px rgba(124, 58, 237, 0.2);
    border-color: rgba(124, 58, 237, 0.3);
  }}
  .stat:hover::before {{ opacity: 1; }}
  .stat .icon {{
    font-size: 1.5rem;
    margin-bottom: 6px;
  }}
  .stat .num {{
    font-size: 2rem;
    font-weight: 700;
    background: linear-gradient(135deg, #7c3aed, #06b6d4);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }}
  .stat .label {{
    font-size: 0.8rem;
    color: #666;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    margin-top: 4px;
  }}

  /* Section dividers */
  .section-divider {{
    height: 1px;
    background: linear-gradient(90deg, transparent, rgba(124, 58, 237, 0.3), transparent);
    margin: 12px 0;
  }}

  /* Chart sections */
  .chart-section {{
    padding: 24px 0;
  }}
  .chart-section h2 {{
    font-size: 1.3rem;
    font-weight: 700;
    margin-bottom: 4px;
    color: #ccc;
    padding-left: 16px;
    border-left: 3px solid transparent;
    border-image: linear-gradient(180deg, #7c3aed, #06b6d4) 1;
    letter-spacing: -0.01em;
  }}
  .chart-section .subtitle {{
    font-size: 0.85rem;
    color: #666;
    margin-bottom: 14px;
    padding-left: 19px;
  }}
  .chart-container {{
    background: #111118;
    border-radius: 16px;
    border: 1px solid #1e1e2e;
    padding: 10px;
    margin-bottom: 30px;
    box-shadow: 0 0 20px rgba(124, 58, 237, 0.06);
    transition: transform 0.3s ease, box-shadow 0.3s ease, border-color 0.3s ease;
  }}
  .chart-container:hover {{
    transform: translateY(-2px);
    box-shadow: 0 4px 32px rgba(124, 58, 237, 0.12);
    border-color: rgba(124, 58, 237, 0.25);
  }}
  .grid-2 {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
  }}
  @media (max-width: 900px) {{
    .grid-2 {{ grid-template-columns: 1fr; }}
    .nav-links {{ gap: 12px; }}
    .header h1 {{ font-size: 2rem; }}
    .stats-row {{ gap: 12px; }}
    .stat {{ min-width: 130px; padding: 16px 20px; }}
  }}

  /* Data attribution */
  .data-attribution {{
    text-align: center;
    color: #444;
    font-size: 0.8rem;
    padding-bottom: 12px;
  }}
  .data-attribution a {{
    color: #7c3aed;
    text-decoration: none;
    transition: color 0.2s;
  }}
  .data-attribution a:hover {{ color: #a78bfa; }}

  /* Install CTA */
  .install-section {{
    text-align: center;
    padding: 40px 20px;
    margin: 20px 0;
    background: rgba(124, 58, 237, 0.04);
    border: 1px solid rgba(124, 58, 237, 0.15);
    border-radius: 16px;
  }}
  .install-section h2 {{
    font-size: 1.3rem;
    font-weight: 700;
    color: #ccc;
    margin-bottom: 8px;
  }}
  .install-section .install-subtitle {{
    color: #666;
    font-size: 0.9rem;
    margin-bottom: 20px;
  }}
  .install-code {{
    display: inline-block;
    background: #0d0d14;
    border: 1px solid rgba(124, 58, 237, 0.25);
    border-radius: 10px;
    padding: 14px 24px;
    font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace;
    font-size: 0.95rem;
    color: #a78bfa;
    letter-spacing: 0.02em;
    position: relative;
    cursor: pointer;
    transition: border-color 0.2s, box-shadow 0.2s;
  }}
  .install-code:hover {{
    border-color: rgba(124, 58, 237, 0.5);
    box-shadow: 0 0 20px rgba(124, 58, 237, 0.15);
  }}
  .install-code .copy-hint {{
    display: block;
    font-size: 0.7rem;
    color: #555;
    margin-top: 6px;
    font-family: 'Inter', sans-serif;
    letter-spacing: 0;
  }}

  /* Footer */
  .footer {{
    text-align: center;
    padding: 32px 20px;
    color: #444;
    font-size: 0.8rem;
    border-top: 1px solid rgba(124, 58, 237, 0.1);
    margin-top: 20px;
  }}
  .footer .footer-brand {{
    font-weight: 700;
    background: linear-gradient(135deg, #7c3aed, #06b6d4);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }}
  .footer a {{ color: #7c3aed; text-decoration: none; transition: color 0.2s; }}
  .footer a:hover {{ color: #a78bfa; }}
</style>
</head>
<body>

<nav class="nav">
  <div class="nav-inner">
    <span class="nav-brand">Skills.sh</span>
    <ul class="nav-links">
      <li><a href="#publishers">Publishers</a></li>
      <li><a href="#top-skills-section">Top Skills</a></li>
      <li><a href="#treemap-section">Treemap</a></li>
      <li><a href="#distribution">Distribution</a></li>
    </ul>
  </div>
</nav>

<div class="container">

<div class="header fade-in d1">
  <h1>Skills.sh Ecosystem Dashboard</h1>
  <p class="tagline">Distribution of {len(skills):,} agent skills across {len(owners):,} publishers</p>
</div>

<div class="stats-row fade-in d2">
  <div class="stat">
    <div class="icon">&#128230;</div>
    <div class="num">{len(skills):,}</div>
    <div class="label">Total Skills</div>
  </div>
  <div class="stat">
    <div class="icon">&#128100;</div>
    <div class="num">{len(owners):,}</div>
    <div class="label">Publishers</div>
  </div>
  <div class="stat">
    <div class="icon">&#128193;</div>
    <div class="num">{sum(o["repos"] for o in owners):,}</div>
    <div class="label">Repos</div>
  </div>
  <div class="stat">
    <div class="icon">&#11015;&#65039;</div>
    <div class="num">{total_installs_label}</div>
    <div class="label">Total Installs</div>
  </div>
</div>
<p class="data-attribution fade-in d2">Data scraped from <a href="https://skills.sh">skills.sh</a> on {today}</p>

<div class="section-divider"></div>

<div class="chart-section grid-2 fade-in d3" id="publishers">
  <div>
    <h2>Top 25 Publishers by Skill Count</h2>
    <p class="subtitle">Who is publishing the most skills?</p>
    <div class="chart-container"><div id="bar-count" style="height:600px;"></div></div>
  </div>
  <div>
    <h2>Top 25 Publishers by Total Installs</h2>
    <p class="subtitle">Who has the most adoption?</p>
    <div class="chart-container"><div id="bar-installs" style="height:600px;"></div></div>
  </div>
</div>

<div class="section-divider"></div>

<div class="chart-section fade-in d4" id="top-skills-section">
  <h2>Top 30 Individual Skills by Installs</h2>
  <p class="subtitle">The most installed individual skills across the ecosystem</p>
  <div class="chart-container"><div id="top-skills" style="height:650px;"></div></div>
</div>

<div class="section-divider"></div>

<div class="chart-section fade-in d5" id="treemap-section">
  <h2>Treemap: Install Share by Publisher</h2>
  <p class="subtitle">Size = total installs. Hover for details. Click to zoom into a publisher's skills.</p>
  <div class="chart-container"><div id="treemap" style="height:550px;"></div></div>
</div>

<div class="section-divider"></div>

<div class="chart-section fade-in d6" id="distribution">
  <h2>Install Distribution: Power Law</h2>
  <p class="subtitle">Log-scale histogram showing the long tail of skill installs</p>
  <div class="chart-container"><div id="histogram" style="height:400px;"></div></div>
</div>

<script>
const skills = {skills_json};
const owners = {owner_json};
const allInstalls = {installs_json};

const plotBg = '#111118';
const paperBg = '#111118';
const gridColor = '#1e1e2e';
const fontColor = '#999';
const colorscale = [
  [0, '#1e1b4b'], [0.2, '#4c1d95'], [0.4, '#7c3aed'],
  [0.6, '#a78bfa'], [0.8, '#06b6d4'], [1, '#22d3ee']
];
const defaultLayout = {{
  paper_bgcolor: paperBg,
  plot_bgcolor: plotBg,
  font: {{ color: fontColor, family: 'Inter, -apple-system, system-ui, sans-serif' }},
  margin: {{ t: 20, b: 40, l: 50, r: 20 }},
}};

// 1. TREEMAP
(() => {{
  const labels = ['All Skills'];
  const parents = [''];
  const values = [0];
  const texts = [''];
  const colors = [0];

  for (const o of owners) {{
    labels.push(o.owner);
    parents.push('All Skills');
    values.push(o.total_installs);
    texts.push(`${{o.owner}}<br>${{o.count}} skills<br>${{(o.total_installs/1000).toFixed(1)}}K installs`);
    colors.push(o.total_installs);
  }}

  for (const o of owners) {{
    for (const s of o.skills) {{
      labels.push(`${{s.name}} (${{o.owner}})`);
      parents.push(o.owner);
      values.push(s.installs);
      texts.push(`${{s.name}}<br>${{s.repo}}<br>${{(s.installs/1000).toFixed(1)}}K installs`);
      colors.push(s.installs);
    }}
  }}

  Plotly.newPlot('treemap', [{{
    type: 'treemap',
    labels, parents, values,
    text: texts,
    hoverinfo: 'text',
    textinfo: 'label',
    marker: {{
      colors: colors,
      colorscale: colorscale,
      line: {{ width: 1, color: '#1e1e2e' }}
    }},
    pathbar: {{ visible: true, textfont: {{ color: '#ccc' }} }},
    tiling: {{ pad: 2 }}
  }}], {{
    ...defaultLayout,
    margin: {{ t: 30, b: 10, l: 10, r: 10 }},
  }}, {{ responsive: true }});
}})();

// 2. BAR: Top 25 by count
(() => {{
  const top25 = owners.slice().sort((a, b) => b.count - a.count).slice(0, 25).reverse();
  Plotly.newPlot('bar-count', [{{
    type: 'bar',
    orientation: 'h',
    y: top25.map(o => o.owner),
    x: top25.map(o => o.count),
    text: top25.map(o => o.count),
    textposition: 'outside',
    textfont: {{ color: '#aaa', size: 11 }},
    marker: {{
      color: top25.map(o => o.count),
      colorscale: colorscale,
      line: {{ width: 0 }}
    }},
    hovertext: top25.map(o => `${{o.owner}}: ${{o.count}} skills, ${{(o.total_installs/1000).toFixed(1)}}K installs`),
    hoverinfo: 'text'
  }}], {{
    ...defaultLayout,
    xaxis: {{ gridcolor: gridColor, color: fontColor, title: 'Skills', autorange: true }},
    yaxis: {{ color: fontColor, tickfont: {{ size: 11 }} }},
    margin: {{ t: 10, b: 50, l: 140, r: 100 }},
  }}, {{ responsive: true }});
}})();

// 3. BAR: Top 25 by installs
(() => {{
  const top25 = owners.slice(0, 25).reverse();
  Plotly.newPlot('bar-installs', [{{
    type: 'bar',
    orientation: 'h',
    y: top25.map(o => o.owner),
    x: top25.map(o => o.total_installs),
    text: top25.map(o => o.total_installs >= 1e6 ? (o.total_installs/1e6).toFixed(1) + 'M' : (o.total_installs/1000).toFixed(0) + 'K'),
    textposition: 'outside',
    textfont: {{ color: '#aaa', size: 11 }},
    marker: {{
      color: top25.map(o => o.total_installs),
      colorscale: colorscale,
      line: {{ width: 0 }}
    }},
    hovertext: top25.map(o => `${{o.owner}}: ${{(o.total_installs/1000).toFixed(1)}}K installs, ${{o.count}} skills`),
    hoverinfo: 'text'
  }}], {{
    ...defaultLayout,
    xaxis: {{ gridcolor: gridColor, color: fontColor, title: 'Total Installs', autorange: true }},
    yaxis: {{ color: fontColor, tickfont: {{ size: 11 }} }},
    margin: {{ t: 10, b: 50, l: 140, r: 100 }},
  }}, {{ responsive: true }});
}})();

// 4. HISTOGRAM: Power law
(() => {{
  const installs = allInstalls;
  Plotly.newPlot('histogram', [{{
    type: 'histogram',
    x: installs.map(v => Math.log10(v)),
    nbinsx: 40,
    marker: {{
      color: '#7c3aed',
      line: {{ width: 1, color: '#4c1d95' }}
    }},
    hovertemplate: 'Log10(installs): %{{x:.1f}}<br>Count: %{{y}}<extra></extra>'
  }}], {{
    ...defaultLayout,
    xaxis: {{
      title: 'Log10(Installs)',
      gridcolor: gridColor, color: fontColor,
      tickvals: [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5],
      ticktext: ['1', '3', '10', '32', '100', '316', '1K', '3.2K', '10K', '32K', '100K', '316K']
    }},
    yaxis: {{ title: 'Number of Skills', gridcolor: gridColor, color: fontColor }},
    margin: {{ t: 10, b: 60, l: 60, r: 20 }},
    bargap: 0.05
  }}, {{ responsive: true }});
}})();

// 5. TOP 30 INDIVIDUAL SKILLS
(() => {{
  const top30 = skills.slice(0, 30).reverse();
  const ownerMap = {{}};
  const palette = ['#7c3aed','#06b6d4','#ec4899','#f59e0b','#10b981','#ef4444','#8b5cf6','#14b8a6','#f97316','#6366f1'];
  let idx = 0;
  for (const s of skills.slice(0, 30)) {{
    const o = s.source.split('/')[0];
    if (!(o in ownerMap)) ownerMap[o] = palette[idx++ % palette.length];
  }}
  const colors = top30.map(s => ownerMap[s.source.split('/')[0]]);

  Plotly.newPlot('top-skills', [{{
    type: 'bar',
    orientation: 'h',
    y: top30.map(s => s.name),
    x: top30.map(s => s.installs),
    text: top30.map(s => s.installs >= 1e6 ? (s.installs/1e6).toFixed(1) + 'M' : (s.installs/1000).toFixed(1) + 'K'),
    textposition: 'outside',
    textfont: {{ color: '#aaa', size: 10 }},
    marker: {{
      color: colors,
      line: {{ width: 0 }}
    }},
    hovertext: top30.map(s => `${{s.name}}<br>${{s.source}}<br>${{(s.installs/1000).toFixed(1)}}K installs`),
    hoverinfo: 'text'
  }}], {{
    ...defaultLayout,
    yaxis: {{ color: fontColor, tickfont: {{ size: 10 }} }},
    xaxis: {{ gridcolor: gridColor, color: fontColor, title: 'Installs', autorange: true }},
    margin: {{ t: 10, b: 50, l: 200, r: 80 }},
  }}, {{ responsive: true }});
}})();
</script>

<div class="section-divider"></div>

<div class="install-section fade-in d7">
  <h2>Generate This Dashboard Yourself</h2>
  <p class="install-subtitle">Install the skill, then ask your agent to build the dashboard. No API keys needed.</p>
  <div class="install-code" onclick="navigator.clipboard.writeText('npx skills add olshansk/agent-skills').then(() => this.querySelector('.copy-hint').textContent = 'Copied!')">
    npx skills add olshansk/agent-skills
    <span class="copy-hint">Click to copy</span>
  </div>
</div>

<div class="footer fade-in d7">
  <span class="footer-brand">Skills.sh</span> &#8212;
  Built with <a href="https://plotly.com/javascript/">Plotly.js</a> &#183;
  Data from <a href="https://skills.sh">skills.sh</a> &#183;
  Created by <a href="https://github.com/Olshansk/agent-skills">Olshansk/agent-skills</a>
</div>

</div><!-- .container -->
</body>
</html>'''


def main():
    parser = argparse.ArgumentParser(description="Generate skills.sh ecosystem dashboard")
    parser.add_argument("--output", "-o", default="index.html", help="Output HTML path")
    parser.add_argument("--json", action="store_true", help="Also dump raw JSON data files")
    parser.add_argument("--no-cache", action="store_true", help="Bypass cache and fetch fresh data")
    args = parser.parse_args()

    skills = fetch_skills(no_cache=args.no_cache)
    owners = aggregate(skills)
    print_summary(skills, owners)

    if args.json:
        json_dir = os.path.dirname(args.output) or "."
        skills_path = os.path.join(json_dir, "skills_raw.json")
        owners_path = os.path.join(json_dir, "skills_owners.json")
        with open(skills_path, "w") as f:
            json.dump(skills, f, indent=2)
        with open(owners_path, "w") as f:
            json.dump(owners, f, indent=2)
        print(f"\nJSON data: {skills_path}, {owners_path}")

    html = build_html(skills, owners)
    with open(args.output, "w") as f:
        f.write(html)
    print(f"\nDashboard written to: {args.output} ({len(html):,} bytes)")


if __name__ == "__main__":
    main()
