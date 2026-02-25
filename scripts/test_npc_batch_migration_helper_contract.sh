#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT_DIR/scripts/run_npc_batch_migration.py"

if [[ ! -x "$HELPER" ]]; then
  echo "[FAIL] helper missing or not executable: $HELPER"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/src/content" "$TMP_DIR/src/modules/npc" "$TMP_DIR/docs/reports"

cat > "$TMP_DIR/src/content/ready.nss" <<'EOF'
void main() {
  string k = "npc_activity_slot";
}
EOF

cat > "$TMP_DIR/src/content/bridgeable.nss" <<'EOF'
void main() {
  string a = "al_slot";
  string b = "al_route_count_default";
}
EOF

cat > "$TMP_DIR/src/content/manual.nss" <<'EOF'
void main() {
  string a = "al_teleport_mode";
}
EOF

cat > "$TMP_DIR/src/modules/npc/npc_legacy_al_bridge_inc.nss" <<'EOF'
void main() {
  string a = "al_slot";
}
EOF

cat > "$TMP_DIR/docs/reports/npc_rollout_readiness_report.json" <<'EOF'
{
  "files": [
    {
      "path": "src/content/ready.nss",
      "tier": "READY",
      "legacy_supported": [],
      "legacy_ambiguous": [],
      "legacy_unsupported": []
    },
    {
      "path": "src/content/bridgeable.nss",
      "tier": "BRIDGEABLE",
      "legacy_supported": ["al_slot", "al_route_count_"],
      "legacy_ambiguous": [],
      "legacy_unsupported": []
    },
    {
      "path": "src/content/manual.nss",
      "tier": "MANUAL",
      "legacy_supported": [],
      "legacy_ambiguous": [],
      "legacy_unsupported": ["al_teleport_mode"]
    },
    {
      "path": "src/modules/npc/npc_legacy_al_bridge_inc.nss",
      "tier": "BRIDGEABLE",
      "legacy_supported": ["al_slot"],
      "legacy_ambiguous": [],
      "legacy_unsupported": []
    }
  ]
}
EOF

before_dry="$(sha256sum "$TMP_DIR/src/content/bridgeable.nss" | cut -d' ' -f1)"
python3 "$HELPER" \
  --repo-root "$TMP_DIR" \
  --readiness-json docs/reports/npc_rollout_readiness_report.json \
  --tier READY \
  --tier BRIDGEABLE \
  --execution-json docs/reports/dry.json \
  --execution-md docs/reports/dry.md >/dev/null
after_dry="$(sha256sum "$TMP_DIR/src/content/bridgeable.nss" | cut -d' ' -f1)"
if [[ "$before_dry" != "$after_dry" ]]; then
  echo "[FAIL] dry-run modified content"
  exit 1
fi

python3 "$HELPER" \
  --repo-root "$TMP_DIR" \
  --readiness-json docs/reports/npc_rollout_readiness_report.json \
  --tier READY \
  --tier BRIDGEABLE \
  --apply \
  --execution-json docs/reports/apply.json \
  --execution-md docs/reports/apply.md >/dev/null

if ! rg -q 'npc_activity_slot' "$TMP_DIR/src/content/bridgeable.nss"; then
  echo "[FAIL] apply did not normalize supported key"
  exit 1
fi
if ! rg -q 'npc_route_count_default' "$TMP_DIR/src/content/bridgeable.nss"; then
  echo "[FAIL] apply did not normalize supported route prefix"
  exit 1
fi
if rg -q 'al_slot|al_route_count_' "$TMP_DIR/src/content/bridgeable.nss"; then
  echo "[FAIL] apply left legacy keys in bridgeable fixture"
  exit 1
fi

if ! rg -q 'al_teleport_mode' "$TMP_DIR/src/content/manual.nss"; then
  echo "[FAIL] manual tier content should remain untouched"
  exit 1
fi
if ! rg -q 'al_slot' "$TMP_DIR/src/modules/npc/npc_legacy_al_bridge_inc.nss"; then
  echo "[FAIL] protected runtime path should remain untouched"
  exit 1
fi

python3 "$HELPER" \
  --repo-root "$TMP_DIR" \
  --readiness-json docs/reports/npc_rollout_readiness_report.json \
  --tier READY \
  --tier BRIDGEABLE \
  --apply \
  --execution-json docs/reports/reapply.json \
  --execution-md docs/reports/reapply.md >/dev/null

python3 - "$TMP_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
first = json.loads((root / "docs/reports/apply.json").read_text(encoding="utf-8"))
second = json.loads((root / "docs/reports/reapply.json").read_text(encoding="utf-8"))

if first["summary"]["changed_files"] != 1:
    raise SystemExit(f"[FAIL] first apply expected changed_files=1, got {first['summary']['changed_files']}")
if second["summary"]["changed_files"] != 0:
    raise SystemExit(f"[FAIL] second apply expected changed_files=0, got {second['summary']['changed_files']}")
if second["summary"]["already_canonical"] < 1:
    raise SystemExit("[FAIL] second apply should report already canonical skips")
if second["summary"]["safe_skips"] < 1:
    raise SystemExit("[FAIL] expected protected path safe skip")

print("[OK] batch migration helper contract checks passed")
PY

echo "[OK] NPC batch migration helper contract checks passed"
