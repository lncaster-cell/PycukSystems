#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/scripts/test_npc_smoke.sh"
NPC_SKIP_SMOKE_IN_FINAL_CHECK=1 bash "$ROOT_DIR/scripts/test_npc_final_pilot_readiness_contract.sh"

echo "[OK] NPC final readiness pipeline passed"
