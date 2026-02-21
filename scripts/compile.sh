#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-check}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER_REL="tools/NWNScriptCompiler.exe"
COMPILER_PATH="$ROOT_DIR/$COMPILER_REL"
INCLUDE_PATH="$ROOT_DIR/tools/scripts"
NWNX_INCLUDE_PATH="$ROOT_DIR/third_party/nwnx_includes"
SOURCE_ROOT_INCLUDE_PATH="$ROOT_DIR/src"
NPC_BEHAVIOR_INCLUDE_PATH="$ROOT_DIR/src/modules/npc_behavior"
STOCK_INCLUDE_SOURCE_PATH="$ROOT_DIR/third_party/nwn2_stock_scripts"
STOCK_INCLUDE_PATH="$ROOT_DIR/.ci/nwn2_stock_scripts"
OUTPUT_DIR="$ROOT_DIR/output"
INCLUDE_ARGS=(
  -i "$STOCK_INCLUDE_PATH"
  -i "$SOURCE_ROOT_INCLUDE_PATH"
  -i "$NPC_BEHAVIOR_INCLUDE_PATH"
  -i "$INCLUDE_PATH"
  -i "$NWNX_INCLUDE_PATH"
)

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
else
  echo "[ERROR] Local compilation requires Windows (native or powershell.exe bridge) or wine."
  echo "[INFO] Preferred option: run from Windows or WSL with powershell.exe available."
  exit 1
fi

prepare_stock_includes() {
  if [[ ! -d "$STOCK_INCLUDE_SOURCE_PATH" ]]; then
    echo "[ERROR] Stock include directory not found: $STOCK_INCLUDE_SOURCE_PATH"
    exit 1
  fi

  rm -rf "$STOCK_INCLUDE_PATH"
  mkdir -p "$STOCK_INCLUDE_PATH"
  cp -R "$STOCK_INCLUDE_SOURCE_PATH"/. "$STOCK_INCLUDE_PATH"/

  if [[ -f "$STOCK_INCLUDE_PATH/nwscript.NSS" && ! -f "$STOCK_INCLUDE_PATH/nwscript.nss" ]]; then
    cp "$STOCK_INCLUDE_PATH/nwscript.NSS" "$STOCK_INCLUDE_PATH/nwscript.nss"
  fi

  if [[ ! -f "$STOCK_INCLUDE_PATH/nwscript.nss" ]]; then
    echo "[ERROR] Missing stock include file: $STOCK_INCLUDE_PATH/nwscript.nss"
    exit 1
  fi
}

prepare_stock_includes

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
    output=$(run_compiler "${INCLUDE_ARGS[@]}" "$file" 2>&1)
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
      run_compile "$file" "${INCLUDE_ARGS[@]}"
      ;;
    build)
      run_compile "$file" "${INCLUDE_ARGS[@]}" -o "$OUTPUT_DIR"
      ;;
    optimize)
      run_compile "$file" -a -y -e "${INCLUDE_ARGS[@]}" -o "$OUTPUT_DIR"
      ;;
  esac
done

echo "[OK] Compilation completed in mode: $MODE (runner: $RUNNER)"
