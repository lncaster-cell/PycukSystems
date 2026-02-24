// NPC behavior module: area OnEnter entrypoint.

#include "npc_behavior_core"

void main()
{
    object oEntering;
    object oArea;
    int nPlayers;

    oEntering = GetEnteringObject();
    if (!GetIsObjectValid(oEntering))
    {
        return;
    }

    oArea = OBJECT_SELF;
    nPlayers = NpcBehaviorCountPlayersInArea(oArea);
    if ((GetIsPC(oEntering) || nPlayers > 0) && !NpcBehaviorAreaIsActive(oArea))
    {
        NpcBehaviorAreaActivate(oArea);
    }
}
