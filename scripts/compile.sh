#!/usr/bin/env bash
set -euo pipefail

# Компилирует все .nss-скрипты из src/.
# Переопределения:
#   NWN_COMPILER="/path/to/compiler(.exe)" NWN_INCLUDE_PATHS="/path/to/includes" bash scripts/compile.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INCLUDE_PATHS="${NWN_INCLUDE_PATHS:-${ROOT_DIR}}"
OVERRIDE_COMPILER="${NWN_COMPILER:-}"

is_managed_dotnet_assembly() {
  local target="$1"

  # Portable эвристика для .NET/Mono-сборок: наличие сигнатуры метаданных BSJB.
  # Для нативных Win32/Win64 .exe (без CLR) эта сигнатура отсутствует.
  strings -a "${target}" 2>/dev/null | grep -q "BSJB"
}

is_pe32_executable() {
  local target="$1"

  python3 - "${target}" <<'PYEOF'
import struct
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = path.read_bytes()
except OSError:
    print("0")
    raise SystemExit(0)

if len(data) < 0x40 or data[:2] != b"MZ":
    print("0")
    raise SystemExit(0)

pe_offset = struct.unpack_from("<I", data, 0x3C)[0]
if pe_offset + 26 >= len(data):
    print("0")
    raise SystemExit(0)

if data[pe_offset:pe_offset + 4] != b"PE\0\0":
    print("0")
    raise SystemExit(0)

opt_magic = struct.unpack_from("<H", data, pe_offset + 24)[0]
print("1" if opt_magic == 0x10B else "0")
PYEOF
}

runner_is_usable() {
  local runner="$1"
  local output

  if ! output="$(${runner} --version 2>&1 || true)"; then
    return 1
  fi

  if grep -qi "Exec format error" <<<"${output}"; then
    return 1
  fi

  return 0
}

resolve_exe_runner() {
  local target="$1"

  if [[ -n "${NWN_COMPILER_RUNNER:-}" ]]; then
    if ! command -v "${NWN_COMPILER_RUNNER}" >/dev/null 2>&1; then
      echo "[ERROR] NWN_COMPILER_RUNNER не найден в PATH: ${NWN_COMPILER_RUNNER}" >&2
      return 1
    fi

    printf '%s\n%s\n' "${NWN_COMPILER_RUNNER}" "${target}"
    return 0
  fi

  if command -v mono >/dev/null 2>&1 && is_managed_dotnet_assembly "${target}"; then
    printf '%s\n%s\n' "mono" "${target}"
    return 0
  fi

  # 32-bit PE требует wine32; попытка запустить его через wine64 в окружении без IA32
  # всегда заканчивается падением (syswow64/ntdll). Отлавливаем заранее.
  if [[ "$(is_pe32_executable "${target}")" == "1" ]]; then
    if command -v wine >/dev/null 2>&1 && runner_is_usable "wine"; then
      printf '%s\n%s\n' "wine" "${target}"
      return 0
    fi

    echo "[ERROR] ${target} является 32-bit Windows PE (PE32), но текущая система не может запустить wine32." >&2
    echo "[HINT] Для этого компилятора нужен рабочий wine32 (IA32 emulation в ядре) либо другой 64-bit бинарник компилятора." >&2
    return 1
  fi

  if command -v /usr/lib/wine/wine64 >/dev/null 2>&1 && runner_is_usable "/usr/lib/wine/wine64"; then
    printf '%s\n%s\n' "/usr/lib/wine/wine64" "${target}"
    return 0
  fi

  if command -v wine >/dev/null 2>&1 && runner_is_usable "wine"; then
    printf '%s\n%s\n' "wine" "${target}"
    return 0
  fi

  echo "[ERROR] Для ${target} не найден подходящий раннер: mono/wine." >&2
  echo "[HINT] Установите mono/wine, либо задайте NWN_COMPILER_RUNNER и/или NWN_COMPILER." >&2
  return 1
}

resolve_compiler_cmd() {
  if [[ -n "${OVERRIDE_COMPILER}" ]]; then
    if [[ -x "${OVERRIDE_COMPILER}" ]]; then
      printf '%s\n' "${OVERRIDE_COMPILER}"
      return 0
    fi

    if [[ -f "${OVERRIDE_COMPILER}" ]]; then
      if [[ "${OVERRIDE_COMPILER}" == *.exe ]]; then
        resolve_exe_runner "${OVERRIDE_COMPILER}"
        return $?
      fi

      echo "[ERROR] NWN_COMPILER указывает на неисполняемый файл: ${OVERRIDE_COMPILER}" >&2
      return 1
    fi

    if command -v "${OVERRIDE_COMPILER}" >/dev/null 2>&1; then
      printf '%s\n' "${OVERRIDE_COMPILER}"
      return 0
    fi

    echo "[ERROR] NWN_COMPILER не найден: ${OVERRIDE_COMPILER}" >&2
    return 1
  fi

  local windows_compiler="${ROOT_DIR}/tools/NWNScriptCompiler.exe"
  if [[ -f "${windows_compiler}" ]]; then
    resolve_exe_runner "${windows_compiler}"
    return $?
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

set +e
COMPILER_OUTPUT="$(${COMPILER_CMD[@]} -y -i "${INCLUDE_PATHS}" "${NSS_FILES[@]}" 2>&1)"
COMPILER_EXIT=$?
set -e

if [[ ${COMPILER_EXIT} -ne 0 ]]; then
  echo "${COMPILER_OUTPUT}" >&2

  if grep -qi "syswow64" <<<"${COMPILER_OUTPUT}"; then
    echo "[HINT] Wine не смог запустить 32-bit рантайм (syswow64). Попробуйте нативный Linux-компилятор через NWN_COMPILER, либо полнофункциональное окружение Wine с 32-bit runtime." >&2
  fi

  if grep -qi "Exec format error" <<<"${COMPILER_OUTPUT}"; then
    echo "[HINT] Выбранный раннер несовместим с архитектурой контейнера. Укажите рабочий раннер через NWN_COMPILER_RUNNER или полный путь в NWN_COMPILER." >&2
  fi

  exit ${COMPILER_EXIT}
fi

echo "${COMPILER_OUTPUT}"
echo "[INFO] Компиляция завершена"
