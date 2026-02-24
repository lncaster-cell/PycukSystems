#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQLITE_API_FILE="$ROOT_DIR/src/integrations/nwnx_sqlite/npc_sql_api_inc.nss"
REPO_FILE="$ROOT_DIR/src/integrations/nwnx_sqlite/npc_repo_inc.nss"
WB_FILE="$ROOT_DIR/src/integrations/nwnx_sqlite/npc_wb_inc.nss"
NPC_CORE_FILE="$ROOT_DIR/src/modules/npc/npc_core.nss"

assert_has() {
  local pattern="$1"
  local file="$2"

  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] missing pattern '$pattern' in $file"
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

# Repository invariants: SQL lives here.
assert_has "const string NPC_SQL_STATE_UPSERT" "$REPO_FILE"
assert_has "const string NPC_SQL_EVENTS_FETCH_UNPROCESSED" "$REPO_FILE"
assert_has "const string NPC_SQL_EVENT_MARK_PROCESSED" "$REPO_FILE"
assert_has "const string NPC_SQL_SCHEDULES_FETCH_DUE" "$REPO_FILE"
assert_has "int NpcRepoUpsertNpcState\(" "$REPO_FILE"
assert_has "int NpcRepoFetchUnprocessedEvents\(" "$REPO_FILE"
assert_has "int NpcRepoMarkEventProcessed\(" "$REPO_FILE"
assert_has "int NpcRepoFetchDueSchedules\(" "$REPO_FILE"

# Repository API signatures must be declared only once (in canonical include).
assert_only_in_repo() {
  local pattern="$1"
  local count

  count=$(rg -n "$pattern" "$ROOT_DIR/src/integrations/nwnx_sqlite"/*.nss | wc -l | tr -d " ")
  if [[ "$count" != "1" ]]; then
    echo "[FAIL] expected exactly one declaration for pattern '$pattern' in nwnx_sqlite includes, got $count"
    exit 1
  fi
}

assert_only_in_repo "int NpcRepoUpsertNpcState\("
assert_only_in_repo "int NpcRepoFetchUnprocessedEvents\("
assert_only_in_repo "int NpcRepoMarkEventProcessed\("
assert_only_in_repo "int NpcRepoFetchDueSchedules\("

# Write-behind minimal contract invariants.
assert_has "int NpcSqliteWriteBehindShouldFlush\(" "$WB_FILE"
assert_has "int NpcSqliteWriteBehindFlush\(" "$WB_FILE"
assert_has "void NpcSqliteWriteBehindApplyWriteResult\(" "$WB_FILE"
assert_has "NPC_SQLITE_WB_WRITE_ERROR_STREAK_LIMIT" "$WB_FILE"
assert_has "NPC_SQLITE_WB_DEGRADED_MODE" "$WB_FILE"

# NPC runtime integration points.
assert_has "#include \"npc_sql_api_inc\"" "$NPC_CORE_FILE"
assert_has "#include \"npc_wb_inc\"" "$NPC_CORE_FILE"
assert_has "NpcSqliteInit\(\);" "$NPC_CORE_FILE"
assert_has "NpcSqliteHealthcheck\(\);" "$NPC_CORE_FILE"
assert_has "NpcSqliteWriteBehindMarkDirty\(\);" "$NPC_CORE_FILE"
assert_has "NpcSqliteWriteBehindShouldFlush\(" "$NPC_CORE_FILE"

echo "[OK] NWNX SQLite contract checks passed"
