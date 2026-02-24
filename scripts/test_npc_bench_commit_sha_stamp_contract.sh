#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BENCH_SCRIPT="$ROOT_DIR/scripts/run_npc_bench.sh"

assert_has_literal() {
  local pattern="$1"
  local file="$2"

  if ! rg -Fq "$pattern" "$file"; then
    echo "[FAIL] missing literal pattern '$pattern' in $file"
    exit 1
  fi
}

assert_has_literal 'pattern = r"- Commit SHA:\s*\*\*(.+?)\*\*\.?"' "$BENCH_SCRIPT"
assert_has_literal 're.search(pattern, text)' "$BENCH_SCRIPT"
assert_has_literal 're.sub(pattern, line, text, count=1)' "$BENCH_SCRIPT"

python3 - <<'PY'
import re

pattern = r"- Commit SHA:\s*\*\*(.+?)\*\*\.?"
line = "- Commit SHA: **abc1234** (`abcdef1234567890`)."
pseudo = {"WORKTREE", "N/A", "UNKNOWN", "TBD", ""}

for raw in ("WORKTREE", "N/A", "UNKNOWN", "TBD"):
    text = f"- Commit SHA: **{raw}**.\n"
    match = re.search(pattern, text)
    if not match:
        raise SystemExit(f"[FAIL] pattern did not match pseudo value {raw!r}")
    current = match.group(1).strip()
    if current.upper() in pseudo:
        text = re.sub(pattern, line, text, count=1)
    if line not in text:
        raise SystemExit(f"[FAIL] replacement did not happen for pseudo value {raw!r}: {text!r}")

text = "- Commit SHA: **deadbeef** (`feedface`).\n"
match = re.search(pattern, text)
if not match:
    raise SystemExit("[FAIL] pattern did not match non-pseudo SHA line")
current = match.group(1).strip()
if current.upper() in pseudo:
    text = re.sub(pattern, line, text, count=1)
if text != "- Commit SHA: **deadbeef** (`feedface`).\n":
    raise SystemExit("[FAIL] non-pseudo SHA line should not be replaced")

print("[OK] stamp_baseline_commit_sha pattern/replacement contract passed")
PY
