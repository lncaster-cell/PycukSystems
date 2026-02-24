#!/usr/bin/env bash
set -euo pipefail

# Подготовка workspace для модульной системы NWN2
mkdir -p \
  docs \
  scripts \
  src/core \
  src/controllers \
  src/modules/npc \
  src/integrations/nwnx_sqlite \
  benchmarks

touch src/core/.gitkeep \
      src/controllers/.gitkeep \
      src/modules/npc/.gitkeep \
      src/integrations/nwnx_sqlite/.gitkeep

echo "[OK] Workspace подготовлен: создана базовая структура для NWN2 модульной системы"
