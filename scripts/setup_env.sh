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
  src/modules/npc \
  tools/npc_behavior_system \
  tools/al_system \
  src/integrations/nwnx_sqlite \
  benchmarks

touch src/core/.gitkeep \
      src/controllers/.gitkeep \
      src/modules/npc/.gitkeep \
      src/integrations/nwnx_sqlite/.gitkeep \
      tools/generators/.gitkeep \
      tools/validators/.gitkeep

echo "[OK] Workspace подготовлен: создана базовая структура для NWN2 модульной системы"
