// NPC behavior module: area OnExit entrypoint.
// Contract: OnExit пересчитывает число активных PC в OBJECT_SELF (area, поднявшая событие).

#include "npc_behavior_core"

void main()
{
    object oArea;
    object oExiting;
    int nPlayers;


    oArea = OBJECT_SELF;
    oExiting = GetExitingObject();
    nPlayers = NpcBehaviorCountPlayersInArea(oArea);

    if (!NpcBehaviorAreaIsActive(oArea))
    {
        return;
    }

    // Invariant: деактивация устойчива к delayed area-list update после выхода.
    if ((GetIsPC(oExiting) && nPlayers <= 1) || (!GetIsPC(oExiting) && nPlayers == 0))
    {
        NpcBehaviorAreaDeactivate(oArea);
    }
}
