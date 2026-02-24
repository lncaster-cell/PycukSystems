// NPC behavior: area tick dispatcher entrypoint (thin wrapper).

#include "npc_core"

void main()
{
    NpcBhvrOnAreaTick(OBJECT_SELF);
}
