// NPC behavior module: area OnExit entrypoint.

#include "npc_behavior_core"
#include "al_dbg"

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
    AL_Dbg("AreaExit OK");
    if (NpcBehaviorCountPlayersInArea(oArea) == 0)
    {
        NpcBehaviorAreaDeactivate(oArea);
    }
}
