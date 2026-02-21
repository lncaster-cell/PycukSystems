#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-check}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER_REL="tools/NWNScriptCompiler.exe"
COMPILER_PATH="$ROOT_DIR/$COMPILER_REL"
# Project-level shared include scripts/helpers (.nss), used by compiler -i lookup.
INCLUDE_PATH="$ROOT_DIR/scripts"
NWNX_INCLUDE_PATH="$ROOT_DIR/third_party/nwnx_includes"
SOURCE_ROOT_INCLUDE_PATH="$ROOT_DIR/src"
NPC_BEHAVIOR_INCLUDE_PATH="$ROOT_DIR/src/modules/npc_behavior"
STOCK_INCLUDE_SOURCE_PATH="$ROOT_DIR/third_party/nwn2_stock_scripts"
STOCK_INCLUDE_PATH="$ROOT_DIR/.ci/nwn2_stock_scripts"
OUTPUT_DIR="$ROOT_DIR/output"
INCLUDE_CANDIDATES=(
  "$STOCK_INCLUDE_PATH"
  "$SOURCE_ROOT_INCLUDE_PATH"
  "$NPC_BEHAVIOR_INCLUDE_PATH"
  "$INCLUDE_PATH"
  "$NWNX_INCLUDE_PATH"
)
INCLUDE_ARGS=()

if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
  echo "[ERROR] Local execution is disabled."
  echo "[INFO] Run compilation only in GitHub Actions workflow: .github/workflows/compile.yml (windows-latest)."
  exit 1
fi

if [[ "${RUNNER_OS:-}" != "Windows" ]]; then
  echo "[ERROR] This script may run only on a GitHub Actions Windows runner."
  echo "[INFO] Current RUNNER_OS=${RUNNER_OS:-unknown}."
  exit 1
fi

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

for include_dir in "${INCLUDE_CANDIDATES[@]}"; do
  if [[ -d "$include_dir" ]]; then
    INCLUDE_ARGS+=( -i "$include_dir" )
  fi
done

mapfile -t FILES < <(find "$ROOT_DIR/src" -type f -name '*.nss' | LC_ALL=C sort)

if [[ "${#FILES[@]}" -eq 0 ]]; then
  echo "[INFO] No .nss files found under src/; nothing to compile."
  exit 0
fi


run_compiler() {
  local args=("$@")

  "$COMPILER_PATH" "${args[@]}"
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

echo "[OK] Compilation completed in mode: $MODE (runner: github-actions-windows)"
