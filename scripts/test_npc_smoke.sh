#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/scripts/test_npc_fairness.sh"
bash "$ROOT_DIR/scripts/test_guardrail_analyzer.sh"
bash "$ROOT_DIR/scripts/test_npc_activity_contract.sh"
bash "$ROOT_DIR/scripts/test_npc_runtime_contour_contract.sh"
bash "$ROOT_DIR/scripts/test_npc_lod_perf_gate.sh"
bash "$ROOT_DIR/scripts/check_npc_legacy_compat_contract.sh"

echo "[OK] NPC smoke tests passed"
