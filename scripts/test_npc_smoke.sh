#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/scripts/test_npc_fairness.sh"
bash "$ROOT_DIR/scripts/test_npc_activity_route_contract.sh"

echo "[OK] NPC smoke tests passed"
