// Pending timestamp/status API internals.

string NPC_PENDING_DAY_CACHE_KEY = "npc_pending_day_cache_key";
string NPC_PENDING_DAY_CACHE_BASE_SEC = "npc_pending_day_cache_base_sec";

int NpcBhvrPendingBuildDayCacheKey(int nCalendarYear, int nMonth, int nCalendarDay)
{
    return nCalendarYear * 1000 + nMonth * 32 + nCalendarDay;
}

int NpcBhvrPendingComputeDayBaseSec(int nCalendarYear, int nMonth, int nCalendarDay)
{
    int nYear;
    int nDays;
    int bLeapYear;

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
    return nDays * 86400;
}

int NpcBhvrPendingNow()
{
    int nCalendarYear;
    int nMonth;
    int nCalendarDay;
    int nHour;
    int nMinute;
    int nSecond;
    int nCacheKey;
    int nCachedKey;
    int nDayBaseSec;
    object oModule;

    // Contract: callers on hot paths should snapshot this once per logical
    // update (event/iteration) and pass it down through *TouchAt/*Set*At APIs
    // to avoid repeated clock reads and to keep NPC/area pending mirrors aligned.
    // Hot-path: build seconds from HH:MM:SS and cached day-base seconds.
    // Heavy calendar/day math is only recomputed on day-cache invalidation
    // (calendar day/year change) and stored on module locals for reuse.
    nCalendarYear = GetCalendarYear();
    nMonth = GetCalendarMonth();
    nCalendarDay = GetCalendarDay();
    nHour = GetTimeHour();
    nMinute = GetTimeMinute();
    nSecond = GetTimeSecond();

    nCacheKey = NpcBhvrPendingBuildDayCacheKey(nCalendarYear, nMonth, nCalendarDay);
    oModule = GetModule();
    nCachedKey = GetLocalInt(oModule, NPC_PENDING_DAY_CACHE_KEY);

    if (nCacheKey != nCachedKey)
    {
        nDayBaseSec = NpcBhvrPendingComputeDayBaseSec(nCalendarYear, nMonth, nCalendarDay);
        SetLocalInt(oModule, NPC_PENDING_DAY_CACHE_KEY, nCacheKey);
        SetLocalInt(oModule, NPC_PENDING_DAY_CACHE_BASE_SEC, nDayBaseSec);
    }

    nDayBaseSec = GetLocalInt(oModule, NPC_PENDING_DAY_CACHE_BASE_SEC);
    return nDayBaseSec + nHour * 3600 + nMinute * 60 + nSecond;
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

void NpcBhvrPendingSetStatusAt(object oNpc, int nStatus, int nNow)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // NPC-local pending status is authoritative for current NPC event-state and
    // must only be reset by explicit terminal clear-paths.
    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_PENDING_STATUS, nStatus);
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

void NpcBhvrPendingSetAtIntReason(object oNpc, int nPriority, int nReasonCode, int nStatus, int nNow)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY, nPriority);
    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_PENDING_REASON_CODE, nReasonCode);
    NpcBhvrPendingSetStatusAt(oNpc, nStatus, nNow);
}

void NpcBhvrPendingSetTrackedAtIntReason(object oArea, object oNpc, int nPriority, int nReasonCode, int nStatus, int nNow)
{
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY, nPriority);
    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_PENDING_REASON_CODE, nReasonCode);
    NpcBhvrPendingSetStatusTrackedAt(oArea, oNpc, nStatus, nNow);
}
