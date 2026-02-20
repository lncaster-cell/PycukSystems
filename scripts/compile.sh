#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-check}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER_REL="tools/NWNScriptCompiler.exe"
COMPILER_PATH="$ROOT_DIR/$COMPILER_REL"
INCLUDE_PATH="$ROOT_DIR/tools/scripts"
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

if command -v wine >/dev/null 2>&1; then
  COMPILER_CMD=(wine "$COMPILER_PATH")
elif command -v mono >/dev/null 2>&1; then
  COMPILER_CMD=(mono "$COMPILER_PATH")
elif [[ "${OS:-}" == "Windows_NT" ]]; then
  COMPILER_CMD=("$COMPILER_PATH")
else
  echo "[ERROR] Local compilation requires one of: wine, mono, or Windows execution."
  echo "[INFO] Install wine (Linux/macOS) or run from Windows."
  exit 1
fi

mapfile -t FILES < <(find "$ROOT_DIR/src" -type f -name '*.nss' | LC_ALL=C sort)

if [[ "${#FILES[@]}" -eq 0 ]]; then
  echo "[INFO] No .nss files found under src/; nothing to compile."
  exit 0
fi

run_compile() {
  local file="$1"
  shift
  echo "Compiling $file"
  "${COMPILER_CMD[@]}" "$@" "$file"
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
    output=$("${COMPILER_CMD[@]}" "$file" 2>&1)
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

echo "[OK] Compilation completed in mode: $MODE"
