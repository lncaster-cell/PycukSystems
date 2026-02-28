// Schedule/slot resolution helpers.

int NpcBhvrActivityIsScheduleEnabled(object oNpc, object oArea);
string NpcBhvrActivityAdapterNormalizeSlot(string sSlot);

string NpcBhvrActivityResolveTimeOfDaySlot(int nHour)
{
    // Canonical daypart mapping:
    // 05-07 dawn, 08-11 morning, 12-16 afternoon, 17-21 evening, 22-04 night.
    if (nHour >= 5 && nHour < 8)
    {
        return NPC_BHVR_ACTIVITY_SLOT_DAWN;
    }

    if (nHour >= 8 && nHour < 12)
    {
        return NPC_BHVR_ACTIVITY_SLOT_MORNING;
    }

    if (nHour >= 12 && nHour < 17)
    {
        return NPC_BHVR_ACTIVITY_SLOT_AFTERNOON;
    }

    if (nHour >= 17 && nHour < 22)
    {
        return NPC_BHVR_ACTIVITY_SLOT_EVENING;
    }

    return NPC_BHVR_ACTIVITY_SLOT_NIGHT;
}

string NpcBhvrActivityResolveScheduledSlotForContext(string sCurrentSlot, int nHour)
{
    // Slot is always time-of-day. Schedule toggle is preserved for compatibility,
    // but no longer redefines slot semantics.
    if (nHour < 0 || nHour > 23)
    {
        return NpcBhvrActivityAdapterNormalizeSlot(sCurrentSlot);
    }

    return NpcBhvrActivityResolveTimeOfDaySlot(nHour);
}
