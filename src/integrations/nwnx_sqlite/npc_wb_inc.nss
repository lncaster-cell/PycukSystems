// NPC write-behind minimal contract API.

#include "npc_sql_api_inc"
#include "npc_repo_runtime_inc"

const string NPC_SQLITE_WB_DIRTY_COUNT = "npc_sqlite_wb_dirty_count";
const string NPC_SQLITE_WB_FLUSH_LAST_TS = "npc_sqlite_wb_flush_last_ts";
const string NPC_SQLITE_WB_WRITE_ERROR_STREAK = "npc_sqlite_wb_write_error_streak";
const string NPC_SQLITE_WB_DEGRADED_MODE = "npc_sqlite_wb_degraded_mode";

const int NPC_SQLITE_WB_BATCH_SIZE_DEFAULT = 16;
const int NPC_SQLITE_WB_FLUSH_INTERVAL_SEC_DEFAULT = 1;
const int NPC_SQLITE_WB_WRITE_ERROR_STREAK_LIMIT = 3;

int NpcSqliteWriteBehindDirtyCount()
{
    return GetLocalInt(GetModule(), NPC_SQLITE_WB_DIRTY_COUNT);
}

void NpcSqliteWriteBehindMarkDirty()
{
    object oModule;

    oModule = GetModule();
    SetLocalInt(oModule, NPC_SQLITE_WB_DIRTY_COUNT, GetLocalInt(oModule, NPC_SQLITE_WB_DIRTY_COUNT) + 1);
}

int NpcSqliteWriteBehindShouldFlush(int nNowTs, int nBatchSize, int nFlushIntervalSec)
{
    int nDirtyCount;
    int nLastFlushTs;

    if (nBatchSize <= 0)
    {
        nBatchSize = NPC_SQLITE_WB_BATCH_SIZE_DEFAULT;
    }
    if (nFlushIntervalSec <= 0)
    {
        nFlushIntervalSec = NPC_SQLITE_WB_FLUSH_INTERVAL_SEC_DEFAULT;
    }

    nDirtyCount = NpcSqliteWriteBehindDirtyCount();
    if (nDirtyCount <= 0)
    {
        return FALSE;
    }

    if (nDirtyCount >= nBatchSize)
    {
        return TRUE;
    }

    nLastFlushTs = GetLocalInt(GetModule(), NPC_SQLITE_WB_FLUSH_LAST_TS);
    if (nNowTs - nLastFlushTs >= nFlushIntervalSec)
    {
        return TRUE;
    }

    return FALSE;
}

void NpcSqliteWriteBehindApplyWriteResult(int nWriteResult)
{
    object oModule;
    int nStreak;

    oModule = GetModule();
    nStreak = GetLocalInt(oModule, NPC_SQLITE_WB_WRITE_ERROR_STREAK);

    if (nWriteResult == NPC_SQLITE_OK)
    {
        SetLocalInt(oModule, NPC_SQLITE_WB_WRITE_ERROR_STREAK, 0);
        SetLocalInt(oModule, NPC_SQLITE_WB_DEGRADED_MODE, FALSE);
        return;
    }

    nStreak = nStreak + 1;
    SetLocalInt(oModule, NPC_SQLITE_WB_WRITE_ERROR_STREAK, nStreak);

    if (nStreak >= NPC_SQLITE_WB_WRITE_ERROR_STREAK_LIMIT)
    {
        // Graceful degradation: ограничиваемся критичными persistence-операциями.
        SetLocalInt(oModule, NPC_SQLITE_WB_DEGRADED_MODE, TRUE);
    }
}

int NpcSqliteWriteBehindFlush(int nNowTs, int nBatchSize)
{
    object oModule;
    int nResult;

    oModule = GetModule();
    if (GetLocalInt(oModule, NPC_SQLITE_WB_DEGRADED_MODE) == TRUE)
    {
        // В degraded-mode исполняем минимально критичную запись.
        nResult = NpcRepoUpsertNpcState();
    }
    else
    {
        // Минимальный контракт: flush выполняет одну write-операцию батча.
        nResult = NpcRepoUpsertNpcState();
    }

    NpcSqliteWriteBehindApplyWriteResult(nResult);
    if (nResult == NPC_SQLITE_OK)
    {
        SetLocalInt(oModule, NPC_SQLITE_WB_DIRTY_COUNT, 0);
        SetLocalInt(oModule, NPC_SQLITE_WB_FLUSH_LAST_TS, nNowTs);
    }

    return nResult;
}
