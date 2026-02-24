// Ring-buffer queue slot/addressing internals.

string NpcBhvrQueueHeadKey(int nPriority)
{
    return "npc_queue_head_" + IntToString(nPriority);
}

string NpcBhvrQueueTailKey(int nPriority)
{
    return "npc_queue_tail_" + IntToString(nPriority);
}

string NpcBhvrQueueCountKey(int nPriority)
{
    return "npc_queue_count_" + IntToString(nPriority);
}

int NpcBhvrQueueRingNextSlot(int nSlot)
{
    if (nSlot < 1 || nSlot >= NPC_BHVR_QUEUE_MAX)
    {
        return 1;
    }

    return nSlot + 1;
}

int NpcBhvrQueueRingPrevSlot(int nSlot)
{
    if (nSlot <= 1 || nSlot > NPC_BHVR_QUEUE_MAX)
    {
        return NPC_BHVR_QUEUE_MAX;
    }

    return nSlot - 1;
}

int NpcBhvrQueueRingLogicalToSlot(object oArea, int nPriority, int nLogicalIndex)
{
    int nCount;
    int nHead;
    int nSlot;

    nCount = GetLocalInt(oArea, NpcBhvrQueueCountKey(nPriority));
    if (nLogicalIndex <= 0 || nLogicalIndex > nCount)
    {
        return 0;
    }

    nHead = GetLocalInt(oArea, NpcBhvrQueueHeadKey(nPriority));
    if (nHead < 1 || nHead > NPC_BHVR_QUEUE_MAX)
    {
        nHead = 1;
    }

    nSlot = nHead + nLogicalIndex - 1;
    while (nSlot > NPC_BHVR_QUEUE_MAX)
    {
        nSlot = nSlot - NPC_BHVR_QUEUE_MAX;
    }

    return nSlot;
}
