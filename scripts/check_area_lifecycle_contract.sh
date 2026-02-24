#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/scripts/check_lifecycle_contract.sh" \
  "$ROOT_DIR/tools/npc_behavior_system/npc_behavior_core.nss" \
  "$ROOT_DIR/src/controllers/lifecycle_controller.nss" \
  "npc_behavior"
