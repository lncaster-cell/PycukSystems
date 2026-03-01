#!/usr/bin/env bash
set -u

# CHECK script for NWN2 script compilation.
# It compiles each .nss file and prints a concise SUMMARY of errors.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPILER_EXE_DEFAULT="$ROOT_DIR/compilator/nwn2_compiler/bin/NWNScriptCompiler.exe"
SOURCE_DIR_DEFAULT="$ROOT_DIR/scripts/al_prototype"

COMPILER_EXE="${COMPILER_EXE:-$COMPILER_EXE_DEFAULT}"
SOURCE_DIR="${SOURCE_DIR:-$SOURCE_DIR_DEFAULT}"
RUNNER="${COMPILER_RUNNER:-}"    # e.g. wine / mono / dotnet
ERROR_PREVIEW_LINES="${ERROR_PREVIEW_LINES:-5}"

usage() {
  cat <<USAGE
Usage: ./check_compile.sh [options]

Options:
  --compiler <path>     Path to compiler executable (default: $COMPILER_EXE_DEFAULT)
  --source-dir <path>   Directory with .nss sources (default: $SOURCE_DIR_DEFAULT)
  --runner <name>       Runtime runner for compiler (example: wine)
  --help                Show this help

Environment variables:
  COMPILER_EXE          Same as --compiler
  SOURCE_DIR            Same as --source-dir
  COMPILER_RUNNER       Same as --runner
  ERROR_PREVIEW_LINES   Number of error lines to print per file in SUMMARY (default: 5)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --compiler)
      COMPILER_EXE="$2"; shift 2 ;;
    --source-dir)
      SOURCE_DIR="$2"; shift 2 ;;
    --runner)
      RUNNER="$2"; shift 2 ;;
    --help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2 ;;
  esac
done

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "CHECK: source directory not found: $SOURCE_DIR" >&2
  exit 2
fi

if [[ ! -f "$COMPILER_EXE" ]]; then
  echo "CHECK: compiler not found: $COMPILER_EXE" >&2
  exit 2
fi

if [[ -n "$RUNNER" ]] && ! command -v "$RUNNER" >/dev/null 2>&1; then
  echo "CHECK: runner '$RUNNER' not found in PATH" >&2
  exit 2
fi

mapfile -t FILES < <(find "$SOURCE_DIR" -maxdepth 1 -type f \( -name '*.nss' -o -name '*.NSS' \) | sort)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "CHECK: no .nss files found in $SOURCE_DIR"
  exit 0
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TOTAL=0
FAILED=0

printf 'CHECK: compiler=%s\n' "$COMPILER_EXE"
printf 'CHECK: source_dir=%s\n' "$SOURCE_DIR"
printf 'CHECK: files=%s\n' "${#FILES[@]}"

for SRC in "${FILES[@]}"; do
  TOTAL=$((TOTAL + 1))
  BASENAME="$(basename "$SRC")"
  LOG_FILE="$TMP_DIR/${BASENAME}.log"

  CMD=()
  if [[ -n "$RUNNER" ]]; then
    CMD+=("$RUNNER")
  fi
  CMD+=("$COMPILER_EXE" "$SRC")

  "${CMD[@]}" >"$LOG_FILE" 2>&1
  RC=$?

  if [[ $RC -ne 0 ]] || rg -qi "\berror\b|\bfatal\b" "$LOG_FILE"; then
    FAILED=$((FAILED + 1))
    {
      echo "FILE: $SRC"
      echo "EXIT_CODE: $RC"
      echo "ERROR_LINES:"
      rg -ni "\berror\b|\bfatal\b" "$LOG_FILE" | head -n "$ERROR_PREVIEW_LINES" || true
      echo "---"
    } >> "$TMP_DIR/summary_errors.txt"
    echo "[FAIL] $BASENAME"
  else
    echo "[OK]   $BASENAME"
  fi
done

echo
echo "SUMMARY"
echo "- total files:  $TOTAL"
echo "- failed files: $FAILED"

if [[ $FAILED -gt 0 ]]; then
  echo
  echo "Ошибки компиляции (первые строки по каждому файлу):"
  cat "$TMP_DIR/summary_errors.txt"
  exit 1
fi

echo "CHECK PASSED: ошибки компиляции не обнаружены."
