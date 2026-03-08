// Module OnClientLeave: attach to the Module OnClientLeave event in the toolset.

#include "al_constants_inc"
#include "al_npc_reg_inc"
#include "al_player_count_inc"

void main()
{
    object oLeaving = GetExitingObject();

    if (!GetIsObjectValid(oLeaving))
    {
        return;
    }

    if (!AL_IsCountedPlayer(oLeaving))
    {
        return;
    }

    object oArea = GetArea(oLeaving);

    if (!GetIsObjectValid(oArea))
    {
        oArea = GetLocalObject(oLeaving, AL_L_LAST_AREA);

        if (!GetIsObjectValid(oArea))
        {
            return;
        }
    }

    if (AL_OnPlayerExitCount(oLeaving, oArea))
    {
        AL_HandleAreaBecameEmpty(oArea);
    }

    DeleteLocalObject(oLeaving, AL_L_LAST_AREA);
}
