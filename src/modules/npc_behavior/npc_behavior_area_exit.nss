// NPC behavior module: area OnExit entrypoint.
// Contract: OnExit пересчитывает число активных PC в OBJECT_SELF (area, поднявшая событие).

#include "npc_behavior_core"
#include "al_dbg"

void main()
{
    object oArea;
    int nPlayers;


    oArea = OBJECT_SELF;
    nPlayers = NpcBehaviorCountPlayersInArea(oArea);
    AL_Dbg("AreaExit OK");

    if (!NpcBehaviorAreaIsActive(oArea))
    {
        return;
    }

    // Invariant: area-controller переходит в STOPPED только при нуле активных PC.
    if (nPlayers == 0)
    {
        NpcBehaviorAreaDeactivate(oArea);
    }
}
