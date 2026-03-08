// Area OnExit: attach to the Area OnExit event in the toolset.

#include "al_npc_reg_inc"
#include "al_player_count_inc"

void main()
{
    object oArea = OBJECT_SELF;
    object oExiting = GetExitingObject();

    if (!GetIsObjectValid(oExiting))
    {
        return;
    }

    if (!AL_IsCountedPlayer(oExiting))
    {
        return;
    }

    if (AL_IsAreaModeOff(oArea))
    {
        return;
    }

    if (!AL_OnPlayerExitCount(oExiting, oArea))
    {
        return;
    }

    AL_DebugLogL1(oArea, OBJECT_INVALID, "AL: freeze begin; area became empty.");
    AL_HandleAreaBecameEmpty(oArea);
}
