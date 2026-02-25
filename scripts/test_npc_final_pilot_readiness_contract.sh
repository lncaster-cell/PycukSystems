#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/scripts/generate_npc_launch_readiness_report.py"

if [[ ! -x "$GENERATOR" ]]; then
  echo "[FAIL] missing launch-readiness generator: $GENERATOR"
  exit 1
fi

if [[ "${NPC_SKIP_SMOKE_IN_FINAL_CHECK:-0}" != "1" ]]; then
  bash "$ROOT_DIR/scripts/test_npc_smoke.sh"
fi

for file in \
  "$ROOT_DIR/docs/npc_go_live_checklist.md" \
  "$ROOT_DIR/docs/npc_pilot_rollout_runbook.md" \
  "$ROOT_DIR/docs/npc_toolset_authoring_contract.md" \
  "$ROOT_DIR/docs/npc_migration_exception_registry.json" \
  "$ROOT_DIR/docs/reports/npc_rollout_readiness_report.json" \
  "$ROOT_DIR/docs/reports/npc_migration_execution_report.json" \
  "$ROOT_DIR/docs/reports/npc_remediation_backlog_report.json"; do
  if [[ ! -f "$file" ]]; then
    echo "[FAIL] required file missing: $file"
    exit 1
  fi
done

python3 "$GENERATOR" \
  --repo-root "$ROOT_DIR" \
  --readiness-json docs/reports/npc_rollout_readiness_report.json \
  --execution-json docs/reports/npc_migration_execution_report.json \
  --backlog-json docs/reports/npc_remediation_backlog_report.json \
  --exceptions-json docs/npc_migration_exception_registry.json \
  --pilot-include-path 'src/integrations/nwnx_sqlite/*' \
  --smoke-status GREEN \
  --report-json docs/reports/npc_launch_readiness_report.json \
  --report-md docs/reports/npc_launch_readiness_report.md >/dev/null

python3 - <<'PY'
import json
from pathlib import Path

report = json.loads(Path('docs/reports/npc_launch_readiness_report.json').read_text(encoding='utf-8'))

if report['summary']['verdict'] != 'GO':
    raise SystemExit(f"[FAIL] expected GO verdict, got {report['summary']['verdict']}")

if report['summary']['open_p1_cases'] != 0:
    raise SystemExit('[FAIL] expected open_p1_cases=0')

criteria = {row['name']: row['status'] for row in report['criteria']}
required = [
    'No OPEN/P1 blockers',
    'No OPEN blockers',
    'Smoke/contracts green',
    'Required governance reports exist',
    'Required launch docs exist',
    'Pilot target is READY/BRIDGEABLE',
    'Execution helper report available',
]
for key in required:
    if criteria.get(key) != 'PASS':
        raise SystemExit(f"[FAIL] criterion not PASS: {key} -> {criteria.get(key)}")

print('[OK] final pilot-readiness report checks passed')
PY

echo "[OK] NPC final pilot-readiness contract checks passed"
