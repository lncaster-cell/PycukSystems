#!/usr/bin/env bash
set -euo pipefail

# Подготовка workspace для модульной системы NWN2
mkdir -p \
  docs \
  scripts \
  tools/generators \
  tools/validators \
  src/core \
  src/controllers \
  src/modules/npc_behavior \
  src/integrations/nwnx_sqlite \
  benchmarks

touch src/core/.gitkeep \
      src/controllers/.gitkeep \
      src/modules/npc_behavior/.gitkeep \
      src/integrations/nwnx_sqlite/.gitkeep \
      tools/generators/.gitkeep \
      tools/validators/.gitkeep \
      benchmarks/.gitkeep

echo "[OK] Workspace подготовлен: создана базовая структура для NWN2 модульной системы"
