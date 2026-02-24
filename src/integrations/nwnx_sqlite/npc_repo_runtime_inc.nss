// NPC persistence repository runtime API.
// Здесь хранятся SQL-строки и thin-функции, необходимые production runtime.

#include "npc_sql_api_inc"

const string NPC_SQL_STATE_UPSERT = "INSERT INTO npc_states(npc_id, area_id, state, state_updated_at, version) VALUES(:npc_id, :area_id, :state, :state_updated_at, :version) ON CONFLICT(npc_id) DO UPDATE SET area_id=excluded.area_id, state=excluded.state, state_updated_at=excluded.state_updated_at, version=excluded.version;";

int NpcRepoUpsertNpcState()
{
    return NpcSqliteSafeWrite(NPC_SQL_STATE_UPSERT);
}
