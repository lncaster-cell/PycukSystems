#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_SCRIPT="$ROOT_DIR/scripts/audit_npc_rollout_readiness.py"
CANONICAL_DOC="$ROOT_DIR/docs/npc_toolset_authoring_contract.md"

if [[ ! -f "$CANONICAL_DOC" ]]; then
  echo "[FAIL] canonical contract doc missing: $CANONICAL_DOC"
  exit 1
fi

if [[ ! -x "$AUDIT_SCRIPT" ]]; then
  echo "[FAIL] audit script missing or not executable: $AUDIT_SCRIPT"
  exit 1
fi

# Contract check: required tiers must remain explicit in the audit tool.
for tier in READY BRIDGEABLE FALLBACK-RISK MANUAL CONFLICTED; do
  if ! rg -q "\"$tier\"" "$AUDIT_SCRIPT"; then
    echo "[FAIL] readiness tier '$tier' not found in audit script"
    exit 1
  fi
done

# Run a fixture-based coverage check to ensure audit and bridge subset stay aligned.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/src"
cat > "$TMP_DIR/src/fixture_legacy_supported.nss" <<'EOF'
void main()
{
    string s = "al_route_count_default";
    string s2 = "al_route_activity_default_0";
    string s3 = "al_slot";
}
EOF

cat > "$TMP_DIR/src/fixture_legacy_unsupported.nss" <<'EOF'
void main()
{
    string s = "al_route_experimental";
    string s2 = "al_teleport_mode";
}
EOF

python3 "$AUDIT_SCRIPT" \
  --repo-root "$TMP_DIR" \
  --scan src \
  --json-out report.json \
  --md-out report.md >/dev/null

python3 - "$TMP_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
report = json.loads((root / "report.json").read_text(encoding="utf-8"))

files = {item["path"]: item for item in report["files"]}

supported = files["src/fixture_legacy_supported.nss"]
unsupported = files["src/fixture_legacy_unsupported.nss"]

if supported["tier"] != "BRIDGEABLE":
    raise SystemExit(f"[FAIL] supported fixture expected BRIDGEABLE, got {supported['tier']}")

if unsupported["tier"] not in {"FALLBACK-RISK", "MANUAL"}:
    raise SystemExit(f"[FAIL] unsupported fixture expected risk tier, got {unsupported['tier']}")

coverage = report["legacy_coverage"]
if coverage["supported_total"] < 3:
    raise SystemExit("[FAIL] supported legacy keys not counted")
if coverage["unsupported_total"] < 1:
    raise SystemExit("[FAIL] unsupported legacy keys not counted")
if coverage["ambiguous_total"] < 1:
    raise SystemExit("[FAIL] ambiguous legacy keys not counted")

hook_wiring = report["hook_wiring"]
if "canonical_contract_exists" not in hook_wiring:
    raise SystemExit("[FAIL] hook wiring summary missing canonical contract presence flag")

print("[OK] rollout readiness fixture contract checks passed")
PY

# Run real audit in-repo to ensure smoke integration paths are healthy.
python3 "$AUDIT_SCRIPT" \
  --repo-root "$ROOT_DIR" \
  --scan src \
  --json-out docs/reports/npc_rollout_readiness_report.json \
  --md-out docs/reports/npc_rollout_readiness_report.md >/dev/null

echo "[OK] NPC rollout readiness audit contract checks passed"
