#!/usr/bin/env bash
set -euo pipefail

# Template: copy to scripts/test_<module_prefix>_smoke.sh
# then replace placeholders.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/scripts/check_<module_prefix>_lifecycle_contract.sh"
# Optional: add module-specific checks below.
# bash "$ROOT_DIR/scripts/test_<module_prefix>_fairness.sh"
# bash "$ROOT_DIR/scripts/test_<module_prefix>_activity_contract.sh"

echo "[OK] <module_prefix> smoke tests passed"
