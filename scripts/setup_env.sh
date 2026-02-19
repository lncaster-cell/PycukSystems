#!/usr/bin/env bash
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  echo "[ERROR] python3 не найден. Установите Python 3.10+ и повторите." >&2
  exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')

if ! python3 - <<'PY'
import sys
sys.exit(0 if sys.version_info >= (3, 10) else 1)
PY
then
  echo "[ERROR] Требуется Python >= 3.10. Найден: ${PYTHON_VERSION}" >&2
  exit 1
fi

if [ ! -d .venv ]; then
  python3 -m venv .venv
  echo "[OK] Создано виртуальное окружение .venv"
else
  echo "[OK] .venv уже существует"
fi

# shellcheck disable=SC1091
source .venv/bin/activate

if python -m pip install --upgrade pip setuptools wheel >/dev/null 2>&1; then
  echo "[OK] Базовые пакеты pip/setuptools/wheel обновлены"
else
  echo "[WARN] Не удалось обновить pip/setuptools/wheel (возможны сетевые ограничения). Продолжаем."
fi

echo "[OK] Окружение готово. Активируйте его командой: source .venv/bin/activate"
