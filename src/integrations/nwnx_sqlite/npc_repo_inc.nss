// NPC persistence repository API.
// Здесь хранятся SQL-строки и thin-функции доступа к persistence-слою.

#include "npc_sql_api_inc"

const string NPC_SQL_STATE_UPSERT =
    "INSERT INTO npc_states(npc_id, area_id, state, state_updated_at, version) " +
    "VALUES(:npc_id, :area_id, :state, :state_updated_at, :version) " +
    "ON CONFLICT(npc_id) DO UPDATE SET " +
    "area_id=excluded.area_id, " +
    "state=excluded.state, " +
    "state_updated_at=excluded.state_updated_at, " +
    "version=excluded.version;";

const string NPC_SQL_EVENTS_FETCH_UNPROCESSED =
    "SELECT event_id, npc_id, event_type, payload_json, created_at " +
    "FROM npc_events " +
    "WHERE processed = 0 " +
    "ORDER BY created_at ASC " +
    "LIMIT :limit;";

const string NPC_SQL_EVENT_MARK_PROCESSED =
    "UPDATE npc_events " +
    "SET processed = 1, processed_at = :processed_at " +
    "WHERE event_id = :event_id;";

const string NPC_SQL_SCHEDULES_FETCH_DUE =
    "SELECT schedule_id, npc_id, task_type, run_at, status, priority " +
    "FROM schedules " +
    "WHERE status = 'pending' AND run_at <= :run_at " +
    "ORDER BY priority DESC, run_at ASC " +
    "LIMIT :limit;";

int NpcRepoUpsertNpcState()
{
    return NpcSqliteSafeWrite(NPC_SQL_STATE_UPSERT);
}

int NpcRepoFetchUnprocessedEvents()
{
    return NpcSqliteSafeRead(NPC_SQL_EVENTS_FETCH_UNPROCESSED);
}

int NpcRepoMarkEventProcessed()
{
    return NpcSqliteSafeWrite(NPC_SQL_EVENT_MARK_PROCESSED);
}

int NpcRepoFetchDueSchedules()
{
    return NpcSqliteSafeRead(NPC_SQL_SCHEDULES_FETCH_DUE);
}
