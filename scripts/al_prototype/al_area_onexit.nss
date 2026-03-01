// Area OnExit: attach to the Area OnExit event in the toolset.

#include "al_npc_reg_inc"

void main()
{
    object oArea = OBJECT_SELF;
    object oExiting = GetExitingObject();

    if (!GetIsObjectValid(oExiting))
    {
        return;
    }

    if (!GetIsPC(oExiting))
    {
        return;
    }

    if (GetLocalInt(oExiting, "al_exit_counted") == 1)
    {
        return;
    }

    SetLocalInt(oExiting, "al_exit_counted", 1);

    int iPlayers = GetLocalInt(oArea, "al_player_count") - 1;
    if (iPlayers < 0)
    {
        iPlayers = 0;
    }

    SetLocalInt(oArea, "al_player_count", iPlayers);

    if (iPlayers != 0)
    {
        return;
    }

    AL_HandleLastPlayerLeaves(oArea);
}
