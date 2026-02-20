#!/usr/bin/env bash
set -euo pipefail

# Компилирует все .nss-скрипты из src/.
# Переопределения:
#   NWN_COMPILER="/path/to/compiler(.exe)" NWN_INCLUDE_PATHS="/path/to/includes" bash scripts/compile.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INCLUDE_PATHS="${NWN_INCLUDE_PATHS:-${ROOT_DIR}}"
OVERRIDE_COMPILER="${NWN_COMPILER:-}"

resolve_compiler_cmd() {
  if [[ -n "${OVERRIDE_COMPILER}" ]]; then
    if [[ ! -f "${OVERRIDE_COMPILER}" ]]; then
      echo "[ERROR] NWN_COMPILER указывает на несуществующий файл: ${OVERRIDE_COMPILER}" >&2
      return 1
    fi

    if [[ -x "${OVERRIDE_COMPILER}" ]]; then
      printf '%s\n' "${OVERRIDE_COMPILER}"
      return 0
    fi

    if command -v mono >/dev/null 2>&1; then
      printf '%s\n%s\n' "mono" "${OVERRIDE_COMPILER}"
      return 0
    fi

    if command -v wine >/dev/null 2>&1; then
      printf '%s\n%s\n' "wine" "${OVERRIDE_COMPILER}"
      return 0
    fi

    echo "[ERROR] NWN_COMPILER задан, но файл не исполняемый и в системе нет mono/wine: ${OVERRIDE_COMPILER}" >&2
    return 1
  fi

  local windows_compiler="${ROOT_DIR}/tools/NWNScriptCompiler.exe"
  if [[ -f "${windows_compiler}" ]]; then
    if command -v mono >/dev/null 2>&1; then
      printf '%s\n%s\n' "mono" "${windows_compiler}"
      return 0
    fi

    if command -v wine >/dev/null 2>&1; then
      printf '%s\n%s\n' "wine" "${windows_compiler}"
      return 0
    fi

    echo "[ERROR] Найден ${windows_compiler}, но в системе нет mono/wine для запуска .exe." >&2
    echo "[HINT] Установите mono/wine или укажите путь к компилятору через NWN_COMPILER." >&2
    return 1
  fi

  echo "[ERROR] Компилятор не найден. Ожидается ${windows_compiler} или путь через NWN_COMPILER." >&2
  return 1
}

if ! COMPILER_CMD_RAW="$(resolve_compiler_cmd)"; then
  exit 1
fi
mapfile -t COMPILER_CMD <<<"${COMPILER_CMD_RAW}"

mapfile -t NSS_FILES < <(find "${ROOT_DIR}/src" -type f -name '*.nss' | sort)

if [[ ${#NSS_FILES[@]} -eq 0 ]]; then
  echo "[INFO] В src/ не найдены .nss файлы для компиляции"
  exit 0
fi

echo "[INFO] Найдено ${#NSS_FILES[@]} .nss файлов"
echo "[INFO] Пути include: ${INCLUDE_PATHS}"
echo "[INFO] Компилятор: ${COMPILER_CMD[*]}"

"${COMPILER_CMD[@]}" -y -i "${INCLUDE_PATHS}" "${NSS_FILES[@]}"

echo "[INFO] Компиляция завершена"
