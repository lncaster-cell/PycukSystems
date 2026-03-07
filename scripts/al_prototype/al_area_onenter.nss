// Area OnEnter: attach to the Area OnEnter event in the toolset.

#include "al_area_tick_inc"
#include "al_area_mode_contract_inc"
#include "al_npc_reg_inc"
#include "al_player_count_inc"

void AL_CacheTrainingPartners(object oArea);

void AL_RunWakePath(object oArea, int iToken)
{
    SetLocalInt(oArea, "al_slot", AL_ComputeTimeSlot());
    AL_CacheTrainingPartners(oArea);
    AL_SyncAreaNPCRegistry(oArea);
    DeleteLocalInt(oArea, "al_routes_cached");
    AL_CacheAreaRoutes(oArea);
    AL_UnhideAndResyncRegisteredNPCs(oArea);
    AL_ScheduleNextAreaTick(oArea, iToken);
}

void AL_CacheTrainingPartners(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (GetLocalInt(oArea, "al_training_partner_cached"))
    {
        return;
    }

    // Preconfigure training partners via toolset/bootstrap on the area:
    // local object "al_training_npc1_ref" + "al_training_npc2_ref".
    object oNpc1 = GetLocalObject(oArea, "al_training_npc1_ref");
    object oNpc2 = GetLocalObject(oArea, "al_training_npc2_ref");

    int bCacheSuccess = GetIsObjectValid(oNpc1)
        && GetArea(oNpc1) == oArea
        && GetIsObjectValid(oNpc2)
        && GetArea(oNpc2) == oArea;

    if (bCacheSuccess)
    {
        SetLocalObject(oArea, "al_training_npc1", oNpc1);
        SetLocalObject(oArea, "al_training_npc2", oNpc2);
        SetLocalInt(oArea, "al_training_partner_cached", TRUE);
        return;
    }

    DeleteLocalObject(oArea, "al_training_npc1");
    DeleteLocalObject(oArea, "al_training_npc2");
    SetLocalInt(oArea, "al_training_partner_cached", FALSE);
}

void main()
{
    object oArea = OBJECT_SELF;
    object oEntering = GetEnteringObject();

    if (!GetIsObjectValid(oEntering))
    {
        return;
    }

    if (!AL_IsCountedPlayer(oEntering))
    {
        return;
    }

    if (AL_IsAreaModeOff(oArea))
    {
        return;
    }

    DeleteLocalInt(oEntering, "al_exit_counted");
    SetLocalObject(oEntering, "al_last_area", oArea);

    int iPlayers = GetLocalInt(oArea, "al_player_count") + 1;
    SetLocalInt(oArea, "al_player_count", iPlayers);

    if (iPlayers != 1)
    {
        return;
    }

    int iToken = GetLocalInt(oArea, "al_tick_token") + 1;
    SetLocalInt(oArea, "al_tick_token", iToken);
    SetLocalInt(oArea, AL_AREA_MODE_LOCAL_KEY, AL_AREA_MODE_HOT);
    SetLocalInt(oArea, "al_slot", AL_ComputeTimeSlot());
    SetLocalInt(oArea, "al_tick_warm_left", AL_TICK_WARM_REPEATS);

    // Soft one-hop neighborhood activation (no scheduler cascade):
    // direct neighbors may be lifted up to WARM only.
    AL_SoftActivateAdjacentAreas(oArea);

    AL_DebugLogL1(oArea, OBJECT_INVALID, "AL: wake begin; area became active.");
    AL_RunWakePath(oArea, iToken);
    AL_DebugLogL2(oArea, OBJECT_INVALID, "AL: wake route cache rebuilt.");
}
