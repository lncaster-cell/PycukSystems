// NPC behavior module: area OnExit entrypoint.

#include "npc_behavior_core"

void main()
{
    object oExiting;
    object oArea;

    oExiting = GetExitingObject();
    if (!GetIsObjectValid(oExiting) || !GetIsPC(oExiting))
    {
        return;
    }

    oArea = GetArea(OBJECT_SELF);
    if (NpcBehaviorCountPlayersInArea(oArea) == 0)
    {
        NpcBehaviorAreaDeactivate(oArea);
    }
}
