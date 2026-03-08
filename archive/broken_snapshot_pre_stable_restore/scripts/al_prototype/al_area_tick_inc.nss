#include "al_constants_inc"
#include "al_area_constants_inc"
#include "al_debug_inc"
#include "al_npc_reg_inc"
#include "al_route_cache_inc"
#include "al_area_mode_contract_inc"

// Shared Area tick helper: period is chosen here (normal vs warm) and
// scheduling always goes through AL_ScheduleNextAreaTick().
// NPC registry synchronization is handled here at the area level only.

const int AL_METRIC_SUMMARY_INTERVAL_TICKS = 20;

void AreaTick(object oArea, int nToken);

void AL_LogAreaMetricSummary(object oArea)
{
    if (!AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
    {
        return;
    }

    AL_DebugLogL1(oArea, OBJECT_INVALID,
        "AL: area metric summary: ticks="
        + IntToString(GetLocalInt(oArea, AL_L_METRIC_SUMMARY_TICK))
        + ", route_resync=" + IntToString(GetLocalInt(oArea, AL_L_METRIC_ROUTE_RESYNC_COUNT))
        + ", activity_fallback=" + IntToString(GetLocalInt(oArea, AL_L_METRIC_ACTIVITY_FALLBACK_COUNT))
        + ", route_truncated=" + IntToString(GetLocalInt(oArea, AL_L_METRIC_ROUTE_TRUNCATED_COUNT))
        + "."
    );
}

int AL_ComputeTimeSlot()
{
    // GetTimeHour() is expected to be in the 0..23 range.
    int iSlot = GetTimeHour() / 4;
    if (iSlot > AL_SLOT_MAX)
    {
        iSlot = AL_SLOT_MAX;
    }

    return iSlot;
}

float AL_GetAreaTickPeriod(object oArea)
{
    if (AL_IsAreaModeHot(oArea))
    {
        return AL_TICK_PERIOD_HOT;
    }

    if (AL_IsAreaModeWarm(oArea))
    {
        return AL_TICK_PERIOD_WARM;
    }

    return AL_TICK_PERIOD_COLD;
}

void AL_ScheduleNextAreaTick(object oArea, int nToken)
{
    if (GetLocalInt(oArea, AL_L_TICK_SCHEDULED_TOKEN) == nToken)
    {
        return;
    }

    SetLocalInt(oArea, AL_L_TICK_SCHEDULED_TOKEN, nToken);
    DelayCommand(AL_GetAreaTickPeriod(oArea), AreaTick(oArea, nToken));
}

void AreaTick(object oArea, int nToken)
{
    if (nToken != GetLocalInt(oArea, AL_L_TICK_TOKEN))
    {
        return;
    }

    if (AL_IsAreaModeOff(oArea) || AL_IsAreaModeCold(oArea))
    {
        DeleteLocalInt(oArea, AL_L_TICK_SCHEDULED_TOKEN);
        return;
    }

    if (GetLocalInt(oArea, AL_L_PLAYER_COUNT) <= 0)
    {
        DeleteLocalInt(oArea, AL_L_TICK_SCHEDULED_TOKEN);
        return;
    }

    DeleteLocalInt(oArea, AL_L_TICK_SCHEDULED_TOKEN);

    int iSummaryTick = GetLocalInt(oArea, AL_L_METRIC_SUMMARY_TICK) + 1;
    SetLocalInt(oArea, AL_L_METRIC_SUMMARY_TICK, iSummaryTick);
    if (iSummaryTick % AL_METRIC_SUMMARY_INTERVAL_TICKS == 0)
    {
        AL_LogAreaMetricSummary(oArea);
    }

    int iSyncTick = GetLocalInt(oArea, AL_L_SYNC_TICK) + 1;
    int bSynced = FALSE;
    if (iSyncTick >= AL_SYNC_TICK_INTERVAL)
    {
        iSyncTick = 0;
        AL_SyncAreaNPCRegistry(oArea);
        bSynced = TRUE;
    }
    SetLocalInt(oArea, AL_L_SYNC_TICK, iSyncTick);

    int iWarmLeft = GetLocalInt(oArea, AL_L_TICK_WARM_LEFT);
    if (iWarmLeft > 0)
    {
        iWarmLeft--;
        if (iWarmLeft > 0)
        {
            SetLocalInt(oArea, AL_L_TICK_WARM_LEFT, iWarmLeft);
        }
        else
        {
            DeleteLocalInt(oArea, AL_L_TICK_WARM_LEFT);
            if (AL_IsAreaModeHot(oArea))
            {
                AL_SetAreaMode(oArea, AL_AREA_MODE_WARM);
            }
        }
    }

    int iSlot = AL_ComputeTimeSlot();
    int iPrevSlot = GetLocalInt(oArea, AL_L_SLOT);

    if (iSlot == iPrevSlot)
    {
        AL_ScheduleNextAreaTick(oArea, nToken);
        return;
    }

    AL_DebugLogL1(oArea, OBJECT_INVALID, "AL: mode transition slot "
        + IntToString(iPrevSlot) + " -> " + IntToString(iSlot) + ".");

    if (!bSynced)
    {
        AL_SyncAreaNPCRegistry(oArea);
    }
    SetLocalInt(oArea, AL_L_SLOT, iSlot);
    AL_BroadcastUserEvent(oArea, AL_EVT_SLOT_0 + iSlot);
    AL_ScheduleNextAreaTick(oArea, nToken);
}
