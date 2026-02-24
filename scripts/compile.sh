#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-check}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER_REL="third_party/toolchain/NWNScriptCompiler.exe"
COMPILER_PATH="$ROOT_DIR/$COMPILER_REL"
INCLUDE_PATH="$ROOT_DIR/scripts"
NWNX_INCLUDE_PATH="$ROOT_DIR/third_party/nwnx_includes"
SOURCE_ROOT_INCLUDE_PATH="$ROOT_DIR/src"
NPC_INCLUDE_PATH="$ROOT_DIR/src/modules/npc"
STOCK_INCLUDE_SOURCE_PATH="$ROOT_DIR/third_party/nwn2_stock_scripts"
STOCK_INCLUDE_PATH="$ROOT_DIR/.ci/nwn2_stock_scripts"
OUTPUT_DIR="$ROOT_DIR/output"
BUGSCAN_LOG_DIR="$ROOT_DIR/.ci/bugscan_logs"
BUGSCAN_SUMMARY_PATH="$ROOT_DIR/.ci/bugscan_summary.json"
BUGSCAN_ANALYZER="$ROOT_DIR/scripts/compile_bugscan_analyze.py"
BUGSCAN_JOBS="${BUGSCAN_JOBS:-1}"

INCLUDE_CANDIDATES=(
  "$STOCK_INCLUDE_PATH"
  "$SOURCE_ROOT_INCLUDE_PATH"
  "$NPC_INCLUDE_PATH"
  "$INCLUDE_PATH"
  "$NWNX_INCLUDE_PATH"
)
INCLUDE_ARGS=()
declare -A SEEN_INCLUDE_DIRS=()
FILES=()

require_github_windows_runner() {
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
}

validate_mode() {
  case "$MODE" in
    check|build|optimize|bugscan) ;;
    *)
      echo "Usage: bash scripts/compile.sh [check|build|optimize|bugscan]"
      exit 2
      ;;
  esac
}

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

append_include_dir() {
  local include_dir="$1"

  if [[ ! -d "$include_dir" ]]; then
    return
  fi

  if [[ -n "${SEEN_INCLUDE_DIRS[$include_dir]:-}" ]]; then
    return
  fi

  SEEN_INCLUDE_DIRS["$include_dir"]=1
  INCLUDE_ARGS+=( -i "$include_dir" )
}

prepare_include_args() {
  local include_dir

  for include_dir in "${INCLUDE_CANDIDATES[@]}"; do
    append_include_dir "$include_dir"
  done

  mapfile -t FILES < <(
    find "$ROOT_DIR/src" -type f -name '*.nss' | LC_ALL=C sort
  )

  if [[ "${#FILES[@]}" -eq 0 ]]; then
    echo "[INFO] No .nss files found under src/; nothing to compile."
    exit 0
  fi

  mapfile -t SRC_INCLUDE_DIRS < <(
    printf '%s\n' "${FILES[@]}" | xargs -r -n1 dirname | LC_ALL=C sort -u
  )

  for include_dir in "${SRC_INCLUDE_DIRS[@]}"; do
    append_include_dir "$include_dir"
  done
}

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

prepare_output_dirs() {
  if [[ "$MODE" == "optimize" ]] && [[ -d "$OUTPUT_DIR" ]]; then
    rm -rf "$OUTPUT_DIR"
  fi

  if [[ "$MODE" == "build" || "$MODE" == "optimize" ]]; then
    mkdir -p "$OUTPUT_DIR"
  fi
}

validate_bugscan_jobs() {
  if ! [[ "$BUGSCAN_JOBS" =~ ^[0-9]+$ ]] || [[ "$BUGSCAN_JOBS" -lt 1 ]]; then
    echo "[ERROR] BUGSCAN_JOBS must be a positive integer. Current value: $BUGSCAN_JOBS"
    exit 2
  fi
}

run_bugscan_compile_to_log() {
  local file="$1"
  local index="$2"
  local log_path="$BUGSCAN_LOG_DIR/$(printf '%06d' "$index").log"
  local output
  local exit_code

  echo "Compiling $file"

  set +e
  output=$(run_compiler -a -y "${INCLUDE_ARGS[@]}" "$file" 2>&1)
  exit_code=$?
  set -e

  {
    printf '__BUGSCAN_SOURCE__=%s\n' "$file"
    printf '__BUGSCAN_EXIT_CODE__=%s\n' "$exit_code"
    printf '__BUGSCAN_OUTPUT_BEGIN__\n'
    printf '%s\n' "$output"
  } > "$log_path"

  printf '%s\n' "$output"
  return 0
}

run_bugscan_compilation() {
  local -i active_jobs=0
  local -i index=0
  local file

  rm -rf "$BUGSCAN_LOG_DIR"
  mkdir -p "$BUGSCAN_LOG_DIR"

  for file in "${FILES[@]}"; do
    index=$((index + 1))
    run_bugscan_compile_to_log "$file" "$index" &
    active_jobs=$((active_jobs + 1))

    if [[ "$active_jobs" -ge "$BUGSCAN_JOBS" ]]; then
      wait -n
      active_jobs=$((active_jobs - 1))
    fi
  done

  wait
}

analyze_bugscan_logs() {
  if [[ ! -f "$BUGSCAN_ANALYZER" ]]; then
    echo "[ERROR] Missing bugscan analyzer script: $BUGSCAN_ANALYZER"
    exit 1
  fi

  mapfile -t BUGSCAN_LOGS < <(
    find "$BUGSCAN_LOG_DIR" -type f -name '*.log' | LC_ALL=C sort
  )

  if [[ "${#BUGSCAN_LOGS[@]}" -eq 0 ]]; then
    echo "[ERROR] Bugscan log files were not produced."
    exit 1
  fi

  echo
  echo "=== BUGSCAN SUMMARY ==="

  python3 "$BUGSCAN_ANALYZER" \
    --format text \
    --json-out "$BUGSCAN_SUMMARY_PATH" \
    "${BUGSCAN_LOGS[@]}"
}

run_standard_compile_modes() {
  local file
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
}

main() {
  require_github_windows_runner
  validate_mode
  prepare_stock_includes
  prepare_include_args
  prepare_output_dirs

  if [[ "$MODE" == "bugscan" ]]; then
    validate_bugscan_jobs
    run_bugscan_compilation
    analyze_bugscan_logs
    exit $?
  fi

  run_standard_compile_modes
  echo "[OK] Compilation completed in mode: $MODE (runner: github-actions-windows)"
}

main "$@"
