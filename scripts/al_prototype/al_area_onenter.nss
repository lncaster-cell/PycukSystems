// Area OnEnter: attach to the Area OnEnter event in the toolset.

#include "al_area_tick_inc"
#include "al_area_mode_contract_inc"
#include "al_constants_inc"
#include "al_npc_reg_inc"
#include "al_player_count_inc"

void AL_CacheTrainingPartners(object oArea);

void AL_RunWakePath(object oArea, int iToken)
{
    SetLocalInt(oArea, AL_L_SLOT, AL_ComputeTimeSlot());
    AL_CacheTrainingPartners(oArea);
    AL_SyncAreaNPCRegistry(oArea);
    DeleteLocalInt(oArea, AL_L_ROUTES_CACHED);
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

    if (GetLocalInt(oArea, AL_L_TRAINING_PARTNER_CACHED))
    {
        return;
    }

    // Preconfigure training partners via toolset/bootstrap on the area:
    // local object AL_L_TRAINING_NPC1_REF + AL_L_TRAINING_NPC2_REF.
    object oNpc1 = GetLocalObject(oArea, AL_L_TRAINING_NPC1_REF);
    object oNpc2 = GetLocalObject(oArea, AL_L_TRAINING_NPC2_REF);

    int bCacheSuccess = GetIsObjectValid(oNpc1)
        && GetArea(oNpc1) == oArea
        && GetIsObjectValid(oNpc2)
        && GetArea(oNpc2) == oArea;

    if (bCacheSuccess)
    {
        SetLocalObject(oArea, AL_L_TRAINING_NPC1, oNpc1);
        SetLocalObject(oArea, AL_L_TRAINING_NPC2, oNpc2);
        SetLocalInt(oArea, AL_L_TRAINING_PARTNER_CACHED, TRUE);
        return;
    }

    DeleteLocalObject(oArea, AL_L_TRAINING_NPC1);
    DeleteLocalObject(oArea, AL_L_TRAINING_NPC2);
    SetLocalInt(oArea, AL_L_TRAINING_PARTNER_CACHED, FALSE);
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

    DeleteLocalInt(oEntering, AL_L_EXIT_COUNTED);
    SetLocalObject(oEntering, AL_L_LAST_AREA, oArea);

    int iPlayers = GetLocalInt(oArea, AL_L_PLAYER_COUNT) + 1;
    SetLocalInt(oArea, AL_L_PLAYER_COUNT, iPlayers);

    if (iPlayers != 1)
    {
        return;
    }

    int iToken = GetLocalInt(oArea, AL_L_TICK_TOKEN) + 1;
    SetLocalInt(oArea, AL_L_TICK_TOKEN, iToken);
    SetLocalInt(oArea, AL_AREA_MODE_LOCAL_KEY, AL_AREA_MODE_HOT);
    SetLocalInt(oArea, AL_L_SLOT, AL_ComputeTimeSlot());
    SetLocalInt(oArea, AL_L_TICK_WARM_LEFT, AL_TICK_WARM_REPEATS);

    // Soft one-hop neighborhood activation (no scheduler cascade):
    // direct neighbors may be lifted up to WARM only.
    AL_SoftActivateAdjacentAreas(oArea);

    AL_DebugLogL1(oArea, OBJECT_INVALID, "AL: wake begin; area became active.");
    AL_RunWakePath(oArea, iToken);
    AL_DebugLogL2(oArea, OBJECT_INVALID, "AL: wake route cache rebuilt.");
}
