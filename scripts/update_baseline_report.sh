#!/usr/bin/env bash
set -euo pipefail

BASELINE_FILE="${1:-docs/perf/npc_baseline_report.md}"

if [[ ! -f "${BASELINE_FILE}" ]]; then
  echo "[ERR] Baseline report not found: ${BASELINE_FILE}" >&2
  exit 2
fi

short_sha="$(git rev-parse --short HEAD 2>/dev/null || true)"
full_sha="$(git rev-parse HEAD 2>/dev/null || true)"

if [[ -z "${short_sha}" || -z "${full_sha}" ]]; then
  echo "[ERR] Unable to resolve git SHA. Run from a git repository checkout." >&2
  exit 2
fi

python3 - "${BASELINE_FILE}" "${short_sha}" "${full_sha}" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
short_sha = sys.argv[2]
full_sha = sys.argv[3]
text = path.read_text(encoding="utf-8")
pattern = r"- Commit SHA:\s*\*\*(.+?)\*\*\.?"

if not re.search(pattern, text):
    raise SystemExit("[ERR] Commit SHA line not found in baseline report")

line = f"- Commit SHA: **{short_sha}** (`{full_sha}`)."
updated = re.sub(pattern, line, text, count=1)
path.write_text(updated, encoding="utf-8")
print(f"[OK] Updated commit SHA in {path}")
PY
