#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/scripts/generate_npc_remediation_backlog.py"
EXCEPTIONS="$ROOT_DIR/docs/npc_migration_exception_registry.json"
BACKLOG_JSON="$ROOT_DIR/docs/reports/npc_remediation_backlog_report.json"
BACKLOG_MD="$ROOT_DIR/docs/reports/npc_remediation_backlog_report.md"

if [[ ! -x "$GENERATOR" ]]; then
  echo "[FAIL] missing backlog generator: $GENERATOR"
  exit 1
fi

python3 "$GENERATOR" \
  --repo-root "$ROOT_DIR" \
  --readiness-json docs/reports/npc_rollout_readiness_report.json \
  --execution-json docs/reports/npc_migration_execution_report.json \
  --exception-registry docs/npc_migration_exception_registry.json \
  --backlog-json docs/reports/npc_remediation_backlog_report.json \
  --backlog-md docs/reports/npc_remediation_backlog_report.md >/dev/null

python3 - "$BACKLOG_JSON" "$EXCEPTIONS" <<'PY'
import json
import pathlib
import sys

backlog = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))
exceptions = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding='utf-8'))

active_ids = {e['id'] for e in exceptions.get('exceptions', []) if e.get('status') == 'active'}

open_p1 = [
    c for c in backlog.get('cases', [])
    if c.get('status') == 'OPEN' and c.get('priority') == 'P1'
]
if open_p1:
    details = ', '.join(f"{c['path']}[{c['category']}]" for c in open_p1)
    raise SystemExit(f"[FAIL] open P1 remediation blockers remain: {details}")

hook_wiring_open = [
    c for c in backlog.get('cases', [])
    if c.get('status') == 'OPEN' and c.get('category') == 'HOOK-WIRING'
]
if hook_wiring_open:
    details = ', '.join(c['path'] for c in hook_wiring_open)
    raise SystemExit(f"[FAIL] open HOOK-WIRING cases remain: {details}")

hook_wiring_exception = [
    c for c in backlog.get('cases', [])
    if c.get('category') == 'HOOK-WIRING' and c.get('status') == 'EXCEPTION'
]
if not hook_wiring_exception:
    raise SystemExit('[FAIL] expected HOOK-WIRING cases to be resolved via explicit exceptions or fixes')

missing_exception_ids = [
    c['exception_id'] for c in backlog.get('cases', [])
    if c.get('status') == 'EXCEPTION' and c.get('exception_id') not in active_ids
]
if missing_exception_ids:
    raise SystemExit(f"[FAIL] backlog references unknown/inactive exceptions: {missing_exception_ids}")

print('[OK] remediation blocker closure checks passed')
PY

echo "[OK] NPC remediation blocker-closure contract checks passed"
