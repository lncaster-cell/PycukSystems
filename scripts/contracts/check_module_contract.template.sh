#!/usr/bin/env bash
set -euo pipefail

# Template: copy to scripts/check_<module_prefix>_lifecycle_contract.sh
# then replace placeholders.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

bash "$ROOT_DIR/scripts/check_lifecycle_contract.sh" \
  "$ROOT_DIR/src/modules/<module_prefix>/<module_prefix>_core.nss" \
  "$ROOT_DIR/src/controllers/lifecycle_controller.nss" \
  "<module_prefix>" \
  "$ROOT_DIR/scripts/contracts/<module_prefix>.contract"
