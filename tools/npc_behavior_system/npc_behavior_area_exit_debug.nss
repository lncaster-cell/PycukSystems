// NPC behavior module: area OnExit DEBUG entrypoint.
// Contract: OnExit пересчитывает число активных PC в OBJECT_SELF (area, поднявшая событие).

#include "npc_behavior_core"
#include "al_dbg"

void main()
{
    object oArea;
    object oExiting;
    int nPlayers;


    oArea = OBJECT_SELF;
    oExiting = GetExitingObject();
    nPlayers = NpcBehaviorCountPlayersInArea(oArea);
    AL_Dbg("AreaExit OK");

    // Invariant: area-controller переходит в STOPPED только при фактическом нуле активных PC.
    // Для PC OnExit учитываем возможную задержку обновления area-list в движке.
    if (NpcBehaviorShouldPauseAreaOnExit(oArea, oExiting, nPlayers))
    {
        NpcBehaviorAreaPause(oArea);
    }
}
