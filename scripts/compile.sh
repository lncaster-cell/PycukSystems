#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-check}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER_REL="tools/NWNScriptCompiler.exe"
COMPILER_PATH="$ROOT_DIR/$COMPILER_REL"
INCLUDE_PATH="$ROOT_DIR/third_party/nwn2_stock_scripts"
OUTPUT_DIR="$ROOT_DIR/output"

if [[ ! -f "$COMPILER_PATH" ]]; then
  echo "[ERROR] Compiler not found: $COMPILER_REL"
  exit 1
fi

case "$MODE" in
  check|build|optimize|bugscan) ;;
  *)
    echo "Usage: bash scripts/compile.sh [check|build|optimize|bugscan]"
    exit 2
    ;;
esac

RUNNER=""
if [[ "${OS:-}" == "Windows_NT" ]]; then
  RUNNER="windows-native"
elif command -v powershell.exe >/dev/null 2>&1; then
  RUNNER="windows-bridge"
elif command -v wine >/dev/null 2>&1; then
  RUNNER="wine"
elif command -v mono >/dev/null 2>&1; then
  RUNNER="mono"
else
  echo "[ERROR] Local compilation requires Windows (native or powershell.exe bridge), wine, or mono."
  echo "[INFO] Preferred option: run from Windows or WSL with powershell.exe available."
  exit 1
fi

mapfile -t FILES < <(find "$ROOT_DIR/src" -type f -name '*.nss' | LC_ALL=C sort)

if [[ "${#FILES[@]}" -eq 0 ]]; then
  echo "[INFO] No .nss files found under src/; nothing to compile."
  exit 0
fi

ps_escape() {
  printf "%s" "$1" | sed "s/'/''/g"
}

to_windows_path() {
  local p="$1"
  if command -v wslpath >/dev/null 2>&1; then
    wslpath -w "$p"
  else
    printf "%s" "$p"
  fi
}

run_compiler() {
  local args=("$@")

  case "$RUNNER" in
    windows-native)
      "$COMPILER_PATH" "${args[@]}"
      ;;
    wine)
      wine "$COMPILER_PATH" "${args[@]}"
      ;;
    mono)
      mono "$COMPILER_PATH" "${args[@]}"
      ;;
    windows-bridge)
      local compiler_win
      compiler_win="$(to_windows_path "$COMPILER_PATH")"

      local ps_cmd="& '$(ps_escape "$compiler_win")'"
      local a
      for a in "${args[@]}"; do
        ps_cmd+=" '$(ps_escape "$(to_windows_path "$a")")'"
      done

      powershell.exe -NoProfile -Command "$ps_cmd"
      ;;
    *)
      echo "[ERROR] Unsupported runner: $RUNNER"
      exit 1
      ;;
  esac
}

run_compile() {
  local file="$1"
  shift
  echo "Compiling $file"
  run_compiler "$@" "$file"
}

if [[ "$MODE" == "optimize" ]] && [[ -d "$OUTPUT_DIR" ]]; then
  rm -rf "$OUTPUT_DIR"
fi
if [[ "$MODE" == "build" || "$MODE" == "optimize" ]]; then
  mkdir -p "$OUTPUT_DIR"
fi

if [[ "$MODE" == "bugscan" ]]; then
  warning_count=0
  error_count=0
  issues=()

  for file in "${FILES[@]}"; do
    echo "Compiling $file"
    set +e
    output=$(run_compiler "$file" 2>&1)
    exit_code=$?
    set -e

    printf '%s\n' "$output"

    while IFS= read -r line; do
      [[ "$line" =~ [Ww][Aa][Rr][Nn][Ii][Nn][Gg] ]] && {
        warning_count=$((warning_count + 1))
        issues+=("[WARNING] $file: $line")
      }
      [[ "$line" =~ [Ee][Rr][Rr][Oo][Rr] ]] && {
        error_count=$((error_count + 1))
        issues+=("[ERROR] $file: $line")
      }
    done <<< "$output"

    if [[ "$exit_code" -ne 0 && ! "$output" =~ [Ee][Rr][Rr][Oo][Rr] ]]; then
      error_count=$((error_count + 1))
      issues+=("[ERROR] $file: compiler exited with code $exit_code")
    fi
  done

  echo
  echo "=== BUGSCAN SUMMARY ==="
  if [[ "${#issues[@]}" -eq 0 ]]; then
    echo "No warnings or errors found."
    exit 0
  fi

  printf '%s\n' "${issues[@]}"
  echo "Total warnings: $warning_count"
  echo "Total errors: $error_count"

  if [[ "$error_count" -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi

for file in "${FILES[@]}"; do
  case "$MODE" in
    check)
      run_compile "$file"
      ;;
    build)
      run_compile "$file" -o "$OUTPUT_DIR"
      ;;
    optimize)
      run_compile "$file" -a -y -e -i "$INCLUDE_PATH" -o "$OUTPUT_DIR"
      ;;
  esac
done

echo "[OK] Compilation completed in mode: $MODE (runner: $RUNNER)"
