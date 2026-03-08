#include "al_area_constants_inc"
#include "al_debug_inc"
#include "al_npc_reg_inc"
#include "al_route_cache_inc"
#include "al_area_mode_contract_inc"

// Shared Area tick helper: period is chosen here (normal vs warm) and
// scheduling always goes through AL_ScheduleNextAreaTick().
// NPC registry synchronization is handled here at the area level only.

void AreaTick(object oArea, int nToken);

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
    if (GetLocalInt(oArea, "al_tick_scheduled_token") == nToken)
    {
        return;
    }

    SetLocalInt(oArea, "al_tick_scheduled_token", nToken);
    DelayCommand(AL_GetAreaTickPeriod(oArea), AreaTick(oArea, nToken));
}

void AreaTick(object oArea, int nToken)
{
    if (nToken != GetLocalInt(oArea, "al_tick_token"))
    {
        return;
    }

    if (AL_IsAreaModeOff(oArea) || AL_IsAreaModeCold(oArea))
    {
        DeleteLocalInt(oArea, "al_tick_scheduled_token");
        return;
    }

    if (GetLocalInt(oArea, "al_player_count") <= 0)
    {
        DeleteLocalInt(oArea, "al_tick_scheduled_token");
        return;
    }

    DeleteLocalInt(oArea, "al_tick_scheduled_token");

    int iSyncTick = GetLocalInt(oArea, "al_sync_tick") + 1;
    int bSynced = FALSE;
    if (iSyncTick >= AL_SYNC_TICK_INTERVAL)
    {
        iSyncTick = 0;
        AL_SyncAreaNPCRegistry(oArea);
        bSynced = TRUE;
    }
    SetLocalInt(oArea, "al_sync_tick", iSyncTick);

    int iWarmLeft = GetLocalInt(oArea, "al_tick_warm_left");
    if (iWarmLeft > 0)
    {
        iWarmLeft--;
        if (iWarmLeft > 0)
        {
            SetLocalInt(oArea, "al_tick_warm_left", iWarmLeft);
        }
        else
        {
            DeleteLocalInt(oArea, "al_tick_warm_left");
            if (AL_IsAreaModeHot(oArea))
            {
                AL_SetAreaMode(oArea, AL_AREA_MODE_WARM);
            }
        }
    }

    int iSlot = AL_ComputeTimeSlot();
    int iPrevSlot = GetLocalInt(oArea, "al_slot");

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
    SetLocalInt(oArea, "al_slot", iSlot);
    AL_BroadcastUserEvent(oArea, AL_EVT_SLOT_0 + iSlot);
    AL_ScheduleNextAreaTick(oArea, nToken);
}
