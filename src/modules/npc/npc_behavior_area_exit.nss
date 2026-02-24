// NPC Bhvr: area OnExit entrypoint (thin wrapper).

#include "npc_core"

void main()
{
    NpcBhvrOnAreaExit(OBJECT_SELF, GetExitingObject());
}
