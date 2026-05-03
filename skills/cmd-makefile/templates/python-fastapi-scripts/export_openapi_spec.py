"""Export the FastAPI OpenAPI spec to `openapi.json` at the repo root.

Usage:
    uv run python scripts/export_openapi_spec.py

Pairs with the `api-export-spec` Make target. The generated file is useful
for spec-diffing in CI, generating typed clients, or publishing API docs.

Adjust the import path below if your app object lives somewhere other than
`app.main:app`.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


def export_openapi_spec(output_file: Path) -> None:
    from app.main import app

    spec = app.openapi()
    output_file.write_text(json.dumps(spec, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    output_file = ROOT / "openapi.json"
    export_openapi_spec(output_file)
    print(f"Wrote {output_file}")


if __name__ == "__main__":
    main()
