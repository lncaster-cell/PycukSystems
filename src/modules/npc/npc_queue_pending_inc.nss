// Pending timestamp/status API internals.

int NpcBhvrPendingNow()
{
    int nYear;
    int nMonth;
    int nCalendarYear;
    int nCalendarDay;
    int nHour;
    int nMinute;
    int nSecond;
    int nDays;
    int bLeapYear;

    // Contract: callers on hot paths should snapshot this once per logical
    // update (event/iteration) and pass it down through *TouchAt/*Set*At APIs
    // to avoid repeated clock reads and to keep NPC/area pending mirrors aligned.
    // Snapshot calendar/time components once to avoid rollover races while
    // building the pending timestamp (e.g. midnight/year transitions).
    nCalendarYear = GetCalendarYear();
    nMonth = GetCalendarMonth();
    nCalendarDay = GetCalendarDay();
    nHour = GetTimeHour();
    nMinute = GetTimeMinute();
    nSecond = GetTimeSecond();

    nYear = nCalendarYear - 2000;

    if (nYear < 0)
    {
        nYear = 0;
    }

    nDays = nYear * 365 + (nYear + 3) / 4 - (nYear + 99) / 100 + (nYear + 399) / 400;

    if (nMonth > 1)
    {
        nDays += 31;
    }
    if (nMonth > 2)
    {
        nDays += 28;
    }
    if (nMonth > 3)
    {
        nDays += 31;
    }
    if (nMonth > 4)
    {
        nDays += 30;
    }
    if (nMonth > 5)
    {
        nDays += 31;
    }
    if (nMonth > 6)
    {
        nDays += 30;
    }
    if (nMonth > 7)
    {
        nDays += 31;
    }
    if (nMonth > 8)
    {
        nDays += 31;
    }
    if (nMonth > 9)
    {
        nDays += 30;
    }
    if (nMonth > 10)
    {
        nDays += 31;
    }
    if (nMonth > 11)
    {
        nDays += 30;
    }

    bLeapYear = (nCalendarYear % 400 == 0) || (nCalendarYear % 4 == 0 && nCalendarYear % 100 != 0);
    if (bLeapYear && nMonth > 2)
    {
        nDays += 1;
    }

    nDays += nCalendarDay - 1;
    return nDays * 86400 + nHour * 3600 + nMinute * 60 + nSecond;
}

void NpcBhvrPendingNpcTouch(object oNpc)
{
    NpcBhvrPendingNpcTouchAt(oNpc, NpcBhvrPendingNow());
}

void NpcBhvrPendingNpcTouchAt(object oNpc, int nNow)
{
    int nPrev;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // Contract: monotonic NPC-local updated_at. Even when caller provides
    // nNow, we advance to prev + 1 on non-increasing timestamps.
    nPrev = GetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_UPDATED_AT);
    if (nNow <= nPrev)
    {
        nNow = nPrev + 1;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_UPDATED_AT, nNow);
}

void NpcBhvrPendingSetStatus(object oNpc, int nStatus)
{
    NpcBhvrPendingSetStatusAt(oNpc, nStatus, NpcBhvrPendingNow());
}

void NpcBhvrPendingSetStatusAt(object oNpc, int nStatus, int nNow)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // NPC-local pending status is authoritative for current NPC event-state and
    // must only be reset by explicit terminal clear-paths.
    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS, nStatus);
    NpcBhvrPendingNpcTouchAt(oNpc, nNow);
}

void NpcBhvrPendingSetStatusTracked(object oArea, object oNpc, int nStatus)
{
    NpcBhvrPendingSetStatusTrackedAt(oArea, oNpc, nStatus, NpcBhvrPendingNow());
}

void NpcBhvrPendingSetStatusTrackedAt(object oArea, object oNpc, int nStatus, int nNow)
{
    int nPrevStatus;
    int nDeferredTotal;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc))
    {
        return;
    }

    nPrevStatus = GetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS);
    if (nPrevStatus == NPC_BHVR_PENDING_STATUS_DEFERRED && nStatus != NPC_BHVR_PENDING_STATUS_DEFERRED)
    {
        nDeferredTotal = NpcBhvrQueueGetDeferredTotal(oArea) - 1;
        NpcBhvrQueueSetDeferredTotal(oArea, nDeferredTotal);
    }
    else if (nPrevStatus != NPC_BHVR_PENDING_STATUS_DEFERRED && nStatus == NPC_BHVR_PENDING_STATUS_DEFERRED)
    {
        nDeferredTotal = NpcBhvrQueueGetDeferredTotal(oArea) + 1;
        NpcBhvrQueueSetDeferredTotal(oArea, nDeferredTotal);
    }

    NpcBhvrPendingSetStatusAt(oNpc, nStatus, nNow);
}

int NpcBhvrPendingIsActive(object oNpc)
{
    int nStatus;

    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    nStatus = GetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS);
    return nStatus == NPC_BHVR_PENDING_STATUS_QUEUED
        || nStatus == NPC_BHVR_PENDING_STATUS_RUNNING
        || nStatus == NPC_BHVR_PENDING_STATUS_DEFERRED;
}

void NpcBhvrPendingSet(object oNpc, int nPriority, string sReason, int nStatus)
{
    NpcBhvrPendingSetAt(oNpc, nPriority, sReason, nStatus, NpcBhvrPendingNow());
}

void NpcBhvrPendingSetAt(object oNpc, int nPriority, string sReason, int nStatus, int nNow)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY, nPriority);
    SetLocalString(oNpc, NPC_BHVR_VAR_PENDING_REASON, sReason);
    NpcBhvrPendingSetStatusAt(oNpc, nStatus, nNow);
}

void NpcBhvrPendingSetTracked(object oArea, object oNpc, int nPriority, string sReason, int nStatus)
{
    NpcBhvrPendingSetTrackedAt(oArea, oNpc, nPriority, sReason, nStatus, NpcBhvrPendingNow());
}

void NpcBhvrPendingSetTrackedAt(object oArea, object oNpc, int nPriority, string sReason, int nStatus, int nNow)
{
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY, nPriority);
    SetLocalString(oNpc, NPC_BHVR_VAR_PENDING_REASON, sReason);
    NpcBhvrPendingSetStatusTrackedAt(oArea, oNpc, nStatus, nNow);
}

