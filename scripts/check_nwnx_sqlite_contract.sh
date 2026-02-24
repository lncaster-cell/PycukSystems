#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQLITE_API_FILE="$ROOT_DIR/src/integrations/nwnx_sqlite/npc_sql_api_inc.nss"
REPO_RUNTIME_FILE="$ROOT_DIR/src/integrations/nwnx_sqlite/npc_repo_runtime_inc.nss"
REPO_EXPERIMENTAL_FILE="$ROOT_DIR/src/integrations/nwnx_sqlite/experimental/npc_repo_contract_inc.nss"
WB_FILE="$ROOT_DIR/src/integrations/nwnx_sqlite/npc_wb_inc.nss"
NPC_CORE_FILE="$ROOT_DIR/src/modules/npc/npc_core.nss"
NPC_LIFECYCLE_FILE="$ROOT_DIR/src/modules/npc/npc_lifecycle_inc.nss"
NPC_QUEUE_FILE="$ROOT_DIR/src/modules/npc/npc_queue_inc.nss"
NPC_TICK_FILE="$ROOT_DIR/src/modules/npc/npc_tick_inc.nss"

assert_has() {
  local pattern="$1"
  local file="$2"

  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] missing pattern '$pattern' in $file"
    exit 1
  fi
}

assert_not_has_in_tree() {
  local pattern="$1"
  local dir="$2"

  if rg -q "$pattern" "$dir"/*.nss; then
    echo "[FAIL] forbidden runtime pattern '$pattern' found in $dir"
    exit 1
  fi
}

# Base API invariants.
assert_has "int NpcSqliteInit\(" "$SQLITE_API_FILE"
assert_has "int NpcSqliteHealthcheck\(" "$SQLITE_API_FILE"
assert_has "NpcSqliteSafeRead\(\"SELECT 1;\"\)" "$SQLITE_API_FILE"
assert_has "int NpcSqliteSafeRead\(" "$SQLITE_API_FILE"
assert_has "int NpcSqliteSafeWrite\(" "$SQLITE_API_FILE"
assert_has "void NpcSqliteLogDbError\(" "$SQLITE_API_FILE"

# Repository invariants: runtime and experimental contract API are split.
assert_has "const string NPC_SQL_STATE_UPSERT" "$REPO_RUNTIME_FILE"
assert_has "int NpcRepoUpsertNpcState\(" "$REPO_RUNTIME_FILE"
assert_has "const string NPC_SQL_EVENTS_FETCH_UNPROCESSED" "$REPO_EXPERIMENTAL_FILE"
assert_has "const string NPC_SQL_EVENT_MARK_PROCESSED" "$REPO_EXPERIMENTAL_FILE"
assert_has "const string NPC_SQL_SCHEDULES_FETCH_DUE" "$REPO_EXPERIMENTAL_FILE"
assert_has "int NpcRepoFetchUnprocessedEvents\(" "$REPO_EXPERIMENTAL_FILE"
assert_has "int NpcRepoMarkEventProcessed\(" "$REPO_EXPERIMENTAL_FILE"
assert_has "int NpcRepoFetchDueSchedules\(" "$REPO_EXPERIMENTAL_FILE"

# Repository API signatures must be declared only once (in canonical include set).
assert_only_in_repo() {
  local pattern="$1"
  local count

  count=$(rg -n "$pattern" "$ROOT_DIR/src/integrations/nwnx_sqlite" --glob "*.nss" | wc -l | tr -d " ")
  if [[ "$count" != "1" ]]; then
    echo "[FAIL] expected exactly one declaration for pattern '$pattern' in nwnx_sqlite includes, got $count"
    exit 1
  fi
}

assert_only_in_repo "int NpcRepoUpsertNpcState\("
assert_only_in_repo "int NpcRepoFetchUnprocessedEvents\("
assert_only_in_repo "int NpcRepoMarkEventProcessed\("
assert_only_in_repo "int NpcRepoFetchDueSchedules\("

assert_not_in_runtime_repo() {
  local pattern="$1"

  if rg -q "$pattern" "$REPO_RUNTIME_FILE"; then
    echo "[FAIL] runtime repository must not expose pattern '$pattern'"
    exit 1
  fi
}

assert_not_in_runtime_repo "int NpcRepoFetchUnprocessedEvents\("
assert_not_in_runtime_repo "int NpcRepoMarkEventProcessed\("
assert_not_in_runtime_repo "int NpcRepoFetchDueSchedules\("

# Write-behind minimal contract invariants.
assert_has "int NpcSqliteWriteBehindShouldFlush\(" "$WB_FILE"
assert_has "int NpcSqliteWriteBehindFlush\(" "$WB_FILE"
assert_has "void NpcSqliteWriteBehindApplyWriteResult\(" "$WB_FILE"
assert_has "NPC_SQLITE_WB_WRITE_ERROR_STREAK_LIMIT" "$WB_FILE"
assert_has "NPC_SQLITE_WB_DEGRADED_MODE" "$WB_FILE"

# NPC runtime integration points.
assert_has "#include \"npc_sql_api_inc\"" "$NPC_CORE_FILE"
assert_has "#include \"npc_wb_inc\"" "$NPC_CORE_FILE"
assert_has "NpcSqliteInit\(\);" "$NPC_LIFECYCLE_FILE"
assert_has "NpcSqliteHealthcheck\(\);" "$NPC_LIFECYCLE_FILE"
assert_has "NpcSqliteWriteBehindMarkDirty\(\);" "$NPC_QUEUE_FILE"
assert_has "NpcSqliteWriteBehindShouldFlush\(" "$NPC_TICK_FILE"
assert_not_has_in_tree "npc_repo_contract_inc" "$ROOT_DIR/src/modules/npc"
assert_not_has_in_tree "experimental/npc_repo_contract_inc" "$ROOT_DIR/src/modules/npc"

# Runtime wiring status for repo API (audit clarity).
# Current expected mode: only state upsert is runtime-wired via write-behind.
assert_has "NpcRepoUpsertNpcState\(" "$WB_FILE"

count_runtime_calls() {
  local pattern="$1"
  local matches

  matches=$(rg -n "$pattern" "$ROOT_DIR/src/modules/npc"/*.nss || true)
  if [[ -z "$matches" ]]; then
    echo "0"
    return
  fi

  printf "%s\n" "$matches" | wc -l | tr -d " "
}

assert_runtime_call_count() {
  local pattern="$1"
  local expected="$2"
  local actual

  actual=$(count_runtime_calls "$pattern")
  if [[ "$actual" != "$expected" ]]; then
    echo "[FAIL] runtime wiring mismatch for '$pattern': expected $expected call(s) in src/modules/npc, got $actual"
    exit 1
  fi
}

assert_runtime_call_count "NpcRepoUpsertNpcState\(" "0"
assert_runtime_call_count "NpcRepoFetchUnprocessedEvents\(" "0"
assert_runtime_call_count "NpcRepoMarkEventProcessed\(" "0"
assert_runtime_call_count "NpcRepoFetchDueSchedules\(" "0"

echo "[OK] runtime wiring status: NpcRepoUpsertNpcState is active via write-behind; events/schedules repo methods are planned in experimental include"
echo "[OK] NWNX SQLite contract checks passed"
