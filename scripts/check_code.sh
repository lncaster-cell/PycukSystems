#!/usr/bin/env bash
set -euo pipefail

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

mapfile -t NSS_FILES < <(find "${ROOT_DIR}" -maxdepth 1 -type f -name '*.nss' | sort)

if [[ ${#NSS_FILES[@]} -eq 0 ]]; then
  echo "[INFO] В репозитории не найдено .nss файлов для проверки"
  exit 0
fi

echo "[INFO] Проверка ${#NSS_FILES[@]} .nss файлов через nwnsc"
echo "[INFO] Пути include: ${INCLUDE_PATHS}"

"${COMPILER}" -y -i "${INCLUDE_PATHS}" "${NSS_FILES[@]}"
