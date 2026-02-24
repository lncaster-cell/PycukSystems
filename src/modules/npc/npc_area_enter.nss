// NPC behavior: area OnEnter entrypoint (thin wrapper).

#include "npc_core"

void main()
{
    NpcBhvrOnAreaEnter(OBJECT_SELF, GetEnteringObject());
}
