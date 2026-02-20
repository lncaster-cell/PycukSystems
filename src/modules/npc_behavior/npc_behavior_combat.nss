// NPC behavior module: combat synchronizer entrypoint (OnEndCombatRound / OnAttacked helpers).

#include "npc_behavior_core"

void main()
{
    NpcBehaviorOnCombatRound(OBJECT_SELF);
}
