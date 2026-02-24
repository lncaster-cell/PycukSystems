// Deprecated compatibility API for external includes.
// Keep only for legacy callers outside src/modules/npc.

// DEPRECATED: use internal lifecycle state transitions from npc_lifecycle_inc.
void NpcBhvrAreaSetState(object oArea, int nState)
{
    NpcBhvrAreaSetStateInternal(oArea, nState);
}

// DEPRECATED: use cached player-count flow from npc_lifecycle_inc internals.
int NpcBhvrCountPlayersInArea(object oArea)
{
    return NpcBhvrCountPlayersInAreaInternalApi(oArea);
}

// DEPRECATED: use cached player-count flow from npc_lifecycle_inc internals.
int NpcBhvrCountPlayersInAreaExcluding(object oArea, object oExclude)
{
    return NpcBhvrCountPlayersInAreaExcludingInternalApi(oArea, oExclude);
}

// DEPRECATED: use cached player-count flow from npc_lifecycle_inc internals.
int NpcBhvrGetCachedPlayerCount(object oArea)
{
    return NpcBhvrGetCachedPlayerCountInternal(oArea);
}
