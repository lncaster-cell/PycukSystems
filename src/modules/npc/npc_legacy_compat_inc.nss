// External-only legacy compatibility API.
// This include is NOT part of npc_core runtime and should be included only by external legacy scripts.

void NpcBhvrAreaSetState(object oArea, int nState)
{
    NpcBhvrAreaSetStateInternal(oArea, nState);
}

int NpcBhvrCountPlayersInArea(object oArea)
{
    return NpcBhvrCountPlayersInAreaInternalApi(oArea);
}

int NpcBhvrCountPlayersInAreaExcluding(object oArea, object oExclude)
{
    return NpcBhvrCountPlayersInAreaExcludingInternalApi(oArea, oExclude);
}

int NpcBhvrGetCachedPlayerCount(object oArea)
{
    return NpcBhvrGetCachedPlayerCountInternal(oArea);
}

void NpcBhvrRegistryBroadcastIdleTick(object oArea)
{
    int nCount;

    nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    NpcBhvrRegistryBroadcastIdleTickBudgeted(oArea, nCount);
}

int NpcBhvrQueuePackLocation(int nPriority, int nIndex)
{
    if (nPriority < NPC_BHVR_PRIORITY_CRITICAL || nPriority > NPC_BHVR_PRIORITY_LOW || nIndex <= 0 || nIndex > NPC_BHVR_QUEUE_MAX)
    {
        return 0;
    }

    return nPriority * 1000 + nIndex;
}
