// Schedule/slot resolution helpers.

string NpcBhvrActivityScheduleStartKey(string sSlot);
string NpcBhvrActivityScheduleEndKey(string sSlot);
int NpcBhvrActivityIsHourInWindow(int nHour, int nStart, int nEnd);
int NpcBhvrActivityIsScheduleEnabled(object oNpc, object oArea);

int NpcBhvrActivityTryResolveScheduledSlot(object oNpc, int nHour, string sSlot)
{
    int nStart;
    int nEnd;
    int bStartPresent;
    int bEndPresent;

    bStartPresent = GetLocalString(oNpc, NpcBhvrActivityScheduleStartKey(sSlot)) != "";
    bEndPresent = GetLocalString(oNpc, NpcBhvrActivityScheduleEndKey(sSlot)) != "";

    if (!bStartPresent || !bEndPresent)
    {
        if (bStartPresent != bEndPresent)
        {
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_ACTIVITY_SCHEDULE_WINDOW_INVALID_TOTAL);
        }
        return FALSE;
    }

    nStart = GetLocalInt(oNpc, NpcBhvrActivityScheduleStartKey(sSlot));
    nEnd = GetLocalInt(oNpc, NpcBhvrActivityScheduleEndKey(sSlot));

    if (!NpcBhvrActivityIsHourInWindow(nHour, nStart, nEnd))
    {
        if (nStart < 0 || nStart > 23 || nEnd < 0 || nEnd > 23 || nStart == nEnd)
        {
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_ACTIVITY_SCHEDULE_WINDOW_INVALID_TOTAL);
        }
        return FALSE;
    }

    return TRUE;
}

string NpcBhvrActivityResolveScheduledSlotForContext(object oNpc, string sCurrentSlot, int bEnabled, int nHour)
{
    if (!GetIsObjectValid(oNpc))
    {
        return sCurrentSlot;
    }

    if (!bEnabled)
    {
        return sCurrentSlot;
    }

    if (NpcBhvrActivityTryResolveScheduledSlot(oNpc, nHour, NPC_BHVR_ACTIVITY_SLOT_CRITICAL))
    {
        return NPC_BHVR_ACTIVITY_SLOT_CRITICAL;
    }

    if (NpcBhvrActivityTryResolveScheduledSlot(oNpc, nHour, NPC_BHVR_ACTIVITY_SLOT_PRIORITY))
    {
        return NPC_BHVR_ACTIVITY_SLOT_PRIORITY;
    }

    return NPC_BHVR_ACTIVITY_SLOT_DEFAULT;
}

string NpcBhvrActivityResolveScheduledSlot(object oNpc, string sCurrentSlot)
{
    object oArea;
    int nHour;

    if (!GetIsObjectValid(oNpc))
    {
        return sCurrentSlot;
    }

    oArea = GetArea(oNpc);
    nHour = GetTimeHour();
    return NpcBhvrActivityResolveScheduledSlotForContext(
        oNpc,
        sCurrentSlot,
        NpcBhvrActivityIsScheduleEnabled(oNpc, oArea),
        nHour
    );
}

