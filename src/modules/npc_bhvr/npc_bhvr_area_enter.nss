// NPC Bhvr: area OnEnter entrypoint (thin wrapper).

#include "npc_bhvr_core"

void main()
{
    NpcBhvrOnAreaEnter(OBJECT_SELF, GetEnteringObject());
}
