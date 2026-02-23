// NPC behavior module: area OnEnter DEBUG entrypoint.

#include "npc_behavior_core"
#include "al_dbg"

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
    AL_Dbg("AreaEnter OK");
    if ((GetIsPC(oEntering) || nPlayers > 0) && !NpcBehaviorAreaIsActive(oArea))
    {
        NpcBehaviorAreaActivate(oArea);
    }
}
