// Queue index + packed-location internals.

string NpcBhvrQueueIndexKey(string sNpcKey)
{
    return "npc_q_idx_" + sNpcKey;
}

int NpcBhvrQueueIndexPriority(object oArea, object oSubject)
{
    string sNpcKey;
    int nPacked;

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    if (sNpcKey == "")
    {
        return -1;
    }

    nPacked = GetLocalInt(oArea, NpcBhvrQueueIndexKey(sNpcKey));
    if (nPacked <= 0)
    {
        return -1;
    }

    return nPacked / 1000;
}

int NpcBhvrQueueIndexPosition(object oArea, object oSubject)
{
    string sNpcKey;
    int nPacked;

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    if (sNpcKey == "")
    {
        return 0;
    }

    nPacked = GetLocalInt(oArea, NpcBhvrQueueIndexKey(sNpcKey));
    if (nPacked <= 0)
    {
        return 0;
    }

    return nPacked - (nPacked / 1000) * 1000;
}

void NpcBhvrQueueIndexClear(object oArea, object oSubject)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    if (sNpcKey == "")
    {
        return;
    }

    DeleteLocalInt(oArea, NpcBhvrQueueIndexKey(sNpcKey));
}

void NpcBhvrQueueIndexSet(object oArea, object oSubject, int nPriority, int nIndex)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject) || nIndex <= 0)
    {
        return;
    }

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    if (sNpcKey == "")
    {
        return;
    }

    SetLocalInt(oArea, NpcBhvrQueueIndexKey(sNpcKey), nPriority * 1000 + nIndex);
}

int NpcBhvrQueuePackLocation(int nPriority, int nIndex)
{
    if (nPriority < NPC_BHVR_PRIORITY_CRITICAL || nPriority > NPC_BHVR_PRIORITY_LOW || nIndex <= 0)
    {
        return 0;
    }

    return nPriority * 1000 + nIndex;
}

