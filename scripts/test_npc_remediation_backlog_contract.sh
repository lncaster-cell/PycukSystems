#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/scripts/generate_npc_remediation_backlog.py"

if [[ ! -x "$GENERATOR" ]]; then
  echo "[FAIL] missing backlog generator: $GENERATOR"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/docs/reports"

cat > "$TMP_DIR/docs/reports/readiness.json" <<'EOF'
{
  "files": [
    {
      "path": "src/content/manual_hook.nss",
      "tier": "MANUAL",
      "legacy_supported": [],
      "legacy_ambiguous": [],
      "legacy_unsupported": [],
      "reasons": ["noncanonical hook-like script naming or wiring"]
    },
    {
      "path": "src/content/conflicted.nss",
      "tier": "CONFLICTED",
      "legacy_supported": [],
      "legacy_ambiguous": [],
      "legacy_unsupported": ["al_teleport_mode"],
      "reasons": ["mixed canonical + legacy/vanilla patterns without explicit migration policy"]
    },
    {
      "path": "src/content/ambiguous.nss",
      "tier": "FALLBACK-RISK",
      "legacy_supported": [],
      "legacy_ambiguous": ["al_route_experimental"],
      "legacy_unsupported": [],
      "reasons": ["ambiguous legacy al_route_* pattern may route to fallback"]
    }
  ],
  "hook_wiring": {
    "canonical_contract_exists": true,
    "canonical_contract_path": "docs/npc_toolset_authoring_contract.md",
    "canonical_hooks": {}
  }
}
EOF

cat > "$TMP_DIR/docs/reports/execution.json" <<'EOF'
{
  "summary": {},
  "results": [
    {
      "path": "src/modules/npc/npc_core.nss",
      "status": "skip",
      "tier": "READY",
      "details": "protected runtime path; content migration not applied",
      "replacements": 0
    }
  ]
}
EOF

cat > "$TMP_DIR/docs/exceptions.json" <<'EOF'
{
  "version": 1,
  "exceptions": [
    {
      "id": "EXC-TEST-PROTECTED",
      "path_pattern": "src/modules/npc/*",
      "category": "RUNTIME-PROTECTED",
      "status": "active",
      "rationale": "Known protected runtime area."
    }
  ]
}
EOF

python3 "$GENERATOR" \
  --repo-root "$TMP_DIR" \
  --readiness-json docs/reports/readiness.json \
  --execution-json docs/reports/execution.json \
  --exception-registry docs/exceptions.json \
  --backlog-json docs/reports/backlog.json \
  --backlog-md docs/reports/backlog.md >/dev/null

python3 - "$TMP_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
report = json.loads((root / "docs/reports/backlog.json").read_text(encoding="utf-8"))

cats = report["summary"]["by_category"]
for required in ("HOOK-WIRING", "CONFLICTED-CONFIG", "LEGACY-UNSUPPORTED", "AMBIGUOUS-ROUTE", "RUNTIME-PROTECTED"):
    if required not in cats:
        raise SystemExit(f"[FAIL] missing category {required}")

priorities = report["summary"]["by_priority"]
if priorities.get("P1", 0) < 2:
    raise SystemExit("[FAIL] expected at least two P1 cases")
if priorities.get("P2", 0) < 1:
    raise SystemExit("[FAIL] expected at least one P2 case")

cases = report["cases"]
protected = [c for c in cases if c["category"] == "RUNTIME-PROTECTED"]
if not protected:
    raise SystemExit("[FAIL] missing runtime-protected case")
if protected[0]["status"] != "EXCEPTION":
    raise SystemExit("[FAIL] runtime-protected case should be exception-tracked")

if report["summary"]["exception_cases"] < 1:
    raise SystemExit("[FAIL] exception count not tracked")

print("[OK] remediation backlog fixture checks passed")
PY

python3 "$GENERATOR" \
  --repo-root "$ROOT_DIR" \
  --readiness-json docs/reports/npc_rollout_readiness_report.json \
  --execution-json docs/reports/npc_migration_execution_report.json \
  --exception-registry docs/npc_migration_exception_registry.json \
  --backlog-json docs/reports/npc_remediation_backlog_report.json \
  --backlog-md docs/reports/npc_remediation_backlog_report.md >/dev/null

echo "[OK] NPC remediation backlog contract checks passed"
