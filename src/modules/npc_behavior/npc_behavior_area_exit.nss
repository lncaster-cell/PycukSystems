// NPC behavior module: area OnExit entrypoint.
// Contract: OnExit counts PCs in OBJECT_SELF (the area that raised the event).

#include "npc_behavior_core"
#include "al_dbg"

void main()
{
    object oExiting;
    object oArea;
    int nPlayers;

    oExiting = GetExitingObject();
    if (!GetIsObjectValid(oExiting))
    {
        return;
    }

    oArea = OBJECT_SELF;
    nPlayers = NpcBehaviorCountPlayersInArea(oArea);
    AL_Dbg("AreaExit OK");

    if (!NpcBehaviorAreaIsActive(oArea))
    {
        return;
    }

    if ((GetIsPC(oExiting) && nPlayers <= 1) || (!GetIsPC(oExiting) && nPlayers == 0))
    {
        NpcBehaviorAreaDeactivate(oArea);
    }
}
