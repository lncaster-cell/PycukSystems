#include "npc_behavior_core"

// NPC behavior module: module OnModuleLoad entrypoint.

void main()
{
    // Bootstrap active areas at module startup to restore area-local tick orchestration
    // without relying on transient OnEnter events after restart/reload.
    NpcBehaviorBootstrapModuleAreas();
}
