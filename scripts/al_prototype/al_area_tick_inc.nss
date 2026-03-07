#include "al_area_constants_inc"
#include "al_npc_reg_inc"
#include "al_route_cache_inc"

// Shared Area tick helper: period is chosen here (normal vs warm) and
// scheduling always goes through AL_ScheduleNextAreaTick().
// NPC registry synchronization is handled here at the area level only.

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
    if (GetLocalInt(oArea, "al_tick_warm_left") > 0)
    {
        return AL_TICK_PERIOD_WARM;
    }

    return AL_TICK_PERIOD;
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
    if (GetLocalInt(oArea, "al_player_count") <= 0)
    {
        return;
    }

    if (nToken != GetLocalInt(oArea, "al_tick_token"))
    {
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
            AL_ScheduleNextAreaTick(oArea, nToken);
            return;
        }

        DeleteLocalInt(oArea, "al_tick_warm_left");
    }

    int iSlot = AL_ComputeTimeSlot();

    if (iSlot == GetLocalInt(oArea, "al_slot"))
    {
        AL_ScheduleNextAreaTick(oArea, nToken);
        return;
    }

    if (!bSynced)
    {
        AL_SyncAreaNPCRegistry(oArea);
    }
    SetLocalInt(oArea, "al_slot", iSlot);
    AL_BroadcastUserEvent(oArea, AL_EVT_SLOT_0 + iSlot);
    AL_ScheduleNextAreaTick(oArea, nToken);
}
