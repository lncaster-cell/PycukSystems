// NPC behavior module: area OnEnter entrypoint.

#include "npc_behavior_core"

void main()
{
    object oEntering;
    object oArea;

    oEntering = GetEnteringObject();
    if (!GetIsObjectValid(oEntering) || !GetIsPC(oEntering))
    {
        return;
    }

    oArea = GetArea(oEntering);
    if (NpcBehaviorCountPlayersInArea(oArea) == 1)
    {
        NpcBehaviorAreaActivate(oArea);
    }
}
