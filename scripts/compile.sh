#!/usr/bin/env bash
set -euo pipefail

# Добавляет удобный скрипт компиляции всех .nss файлов в папке src/
# Использование:
#   NWN_INCLUDE_PATHS="/path/to/nwn/includes" bash scripts/compile.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER="${ROOT_DIR}/nwnsc"
INCLUDE_PATHS="${NWN_INCLUDE_PATHS:-${ROOT_DIR}}"

if [[ ! -f "${COMPILER}" ]]; then
  echo "[ERROR] nwnsc не найден по пути ${COMPILER}" >&2
  exit 1
fi

if [[ ! -x "${COMPILER}" ]]; then
  chmod +x "${COMPILER}"
fi

mapfile -t NSS_FILES < <(find "${ROOT_DIR}/src" -type f -name '*.nss' | sort)

if [[ ${#NSS_FILES[@]} -eq 0 ]]; then
  echo "[INFO] В src/ не найдено .nss файлов для компиляции"
  exit 0
fi

echo "[INFO] Компиляция ${#NSS_FILES[@]} .nss файлов через nwnsc"
echo "[INFO] Пути include: ${INCLUDE_PATHS}"

# Запускаем компиляцию. nwnsc сам создаст выходные файлы рядом с исходниками.
"${COMPILER}" -y -i "${INCLUDE_PATHS}" "${NSS_FILES[@]}"

echo "[INFO] Компиляция завершена"
