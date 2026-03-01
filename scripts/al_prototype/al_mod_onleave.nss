// Module OnClientLeave: attach to the Module OnClientLeave event in the toolset.

#include "al_npc_reg_inc"

void main()
{
    object oLeaving = GetExitingObject();

    if (!GetIsObjectValid(oLeaving))
    {
        return;
    }

    if (!GetIsPC(oLeaving))
    {
        return;
    }

    if (GetLocalInt(oLeaving, "al_exit_counted") == 1)
    {
        return;
    }

    object oArea = GetArea(oLeaving);

    if (!GetIsObjectValid(oArea))
    {
        oArea = GetLocalObject(oLeaving, "al_last_area");

        if (!GetIsObjectValid(oArea))
        {
            return;
        }
    }

    SetLocalInt(oLeaving, "al_exit_counted", 1);

    int iPlayers = GetLocalInt(oArea, "al_player_count") - 1;
    if (iPlayers < 0)
    {
        iPlayers = 0;
    }

    SetLocalInt(oArea, "al_player_count", iPlayers);

    if (iPlayers != 0)
    {
        DeleteLocalObject(oLeaving, "al_last_area");
        return;
    }

    AL_HandleAreaBecameEmpty(oArea);
    DeleteLocalObject(oLeaving, "al_last_area");
}
