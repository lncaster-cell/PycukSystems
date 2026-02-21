// NPC behavior module: area OnEnter entrypoint.

#include "npc_behavior_core"
#include "al_dbg"

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
    AL_Dbg("AreaEnter OK");
    if (NpcBehaviorCountPlayersInArea(oArea) == 1)
    {
        NpcBehaviorAreaActivate(oArea);
    }
}
