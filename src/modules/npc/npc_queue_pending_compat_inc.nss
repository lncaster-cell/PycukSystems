// Legacy compatibility wrappers for pre-At pending APIs.
// Runtime queue-processing must use explicit *At variants and pass shared nNow.

void NpcBhvrPendingNpcTouch(object oNpc)
{
    NpcBhvrPendingNpcTouchAt(oNpc, NpcBhvrPendingNow());
}

void NpcBhvrPendingSetStatus(object oNpc, int nStatus)
{
    NpcBhvrPendingSetStatusAt(oNpc, nStatus, NpcBhvrPendingNow());
}

void NpcBhvrPendingSet(object oNpc, int nPriority, string sReason, int nStatus)
{
    NpcBhvrPendingSetAt(oNpc, nPriority, sReason, nStatus, NpcBhvrPendingNow());
}

void NpcBhvrPendingSetTracked(object oArea, object oNpc, int nPriority, string sReason, int nStatus)
{
    NpcBhvrPendingSetTrackedAt(oArea, oNpc, nPriority, sReason, nStatus, NpcBhvrPendingNow());
}
