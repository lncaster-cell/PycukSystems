#ifndef DL_RESOLVER_INC_NSS
#define DL_RESOLVER_INC_NSS

#include "dl_const_inc"
#include "dl_types_inc"
#include "dl_schedule_inc"
#include "dl_override_inc"

// Legacy compatibility include.
// New runtime entry scripts should prefer the compile-safe aggregation path via dl_all_inc.

int DL_IsSocialScheduleWindow(int nScheduleWindow)
{
    return nScheduleWindow == DL_WIN_SOCIAL || nScheduleWindow == DL_WIN_LATE_SOCIAL;
}

int DL_IsDutyScheduleWindow(int nScheduleWindow)
{
    return nScheduleWindow == DL_WIN_DAY_DUTY || nScheduleWindow == DL_WIN_NIGHT_DUTY;
}

int DL_IsDutyDirective(int nDirective)
{
    return nDirective == DL_DIR_DUTY || nDirective == DL_DIR_HOLD_POST;
}

int DL_IsWorkOrServiceDirective(int nDirective)
{
    return nDirective == DL_DIR_WORK || nDirective == DL_DIR_SERVICE;
}

int DL_IsUnavailableDirective(int nDirective)
{
    return nDirective == DL_DIR_UNASSIGNED || nDirective == DL_DIR_ABSENT;
}

int DL_ResolveDirectiveFromSchedule(object oNPC, int nScheduleWindow, int nDayType)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = DL_GetNpcSubtype(oNPC);

    if (!DL_HasBase(oNPC))
    {
        return DL_DIR_ABSENT;
    }

    if (nScheduleWindow == DL_WIN_SLEEP)
    {
        return DL_DIR_SLEEP;
    }

    if (nFamily == DL_FAMILY_LAW)
    {
        if (DL_IsDutyScheduleWindow(nScheduleWindow))
        {
            if (nSubtype == DL_SUBTYPE_GATE_POST)
            {
                return DL_DIR_HOLD_POST;
            }
            return DL_DIR_DUTY;
        }
        if (nScheduleWindow == DL_WIN_PUBLIC_IDLE)
        {
            return DL_DIR_PUBLIC_PRESENCE;
        }
        return DL_DIR_SLEEP;
    }

    if (nFamily == DL_FAMILY_CRAFT)
    {
        if (nScheduleWindow == DL_WIN_WORK_CORE)
        {
            return DL_DIR_WORK;
        }
        if (DL_IsSocialScheduleWindow(nScheduleWindow) || nDayType == DL_DAY_REST)
        {
            return DL_DIR_SOCIAL;
        }
        return DL_DIR_PUBLIC_PRESENCE;
    }

    if (nFamily == DL_FAMILY_TRADE_SERVICE)
    {
        if (nScheduleWindow == DL_WIN_SERVICE_CORE)
        {
            return DL_DIR_SERVICE;
        }
        if (nScheduleWindow == DL_WIN_LATE_SOCIAL)
        {
            if (nSubtype == DL_SUBTYPE_INNKEEPER)
            {
                return DL_DIR_SERVICE;
            }
            return DL_DIR_SOCIAL;
        }
        if (nScheduleWindow == DL_WIN_SOCIAL)
        {
            return DL_DIR_SOCIAL;
        }
        return DL_DIR_PUBLIC_PRESENCE;
    }

    if (DL_IsSocialScheduleWindow(nScheduleWindow))
    {
        return DL_DIR_SOCIAL;
    }
    return DL_DIR_PUBLIC_PRESENCE;
}

int DL_ApplyOverrideToDirective(object oNPC, int nDirective, int nOverrideKind)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = DL_GetNpcSubtype(oNPC);

    if (nOverrideKind == DL_OVR_FIRE)
    {
        if (nFamily == DL_FAMILY_LAW)
        {
            return DL_DIR_HOLD_POST;
        }
        return DL_DIR_HIDE_SAFE;
    }

    if (nOverrideKind == DL_OVR_QUARANTINE)
    {
        if (nFamily == DL_FAMILY_LAW)
        {
            if (nSubtype == DL_SUBTYPE_GATE_POST)
            {
                return DL_DIR_HOLD_POST;
            }
            return DL_DIR_DUTY;
        }
        return DL_DIR_LOCKDOWN_BASE;
    }

    return nDirective;
}

int DL_GetSupportedFallbackDirective(object oNPC)
{
    if (DL_SupportsDirective(oNPC, DL_DIR_SLEEP))
    {
        return DL_DIR_SLEEP;
    }
    if (DL_SupportsDirective(oNPC, DL_DIR_SOCIAL))
    {
        return DL_DIR_SOCIAL;
    }
    if (DL_SupportsDirective(oNPC, DL_DIR_PUBLIC_PRESENCE))
    {
        return DL_DIR_PUBLIC_PRESENCE;
    }
    if (DL_SupportsDirective(oNPC, DL_DIR_ABSENT))
    {
        return DL_DIR_ABSENT;
    }
    return DL_DIR_ABSENT;
}

int DL_ResolveDirective(object oNPC, object oArea)
{
    int nDayType = DL_DetermineDayType(oArea);
    int nMinute = DL_GetCurrentMinuteOfDay();
    int nOffset = DL_GetPersonalTimeOffset(oNPC);
    int nTemplate = DL_GetScheduleTemplate(oNPC);
    int nWindow = DL_DetermineScheduleWindow(nTemplate, nDayType, nMinute, nOffset);
    int nDirective = DL_ResolveDirectiveFromSchedule(oNPC, nWindow, nDayType);
    int nOverrideKind = DL_GetTopOverride(oNPC, oArea);

    nDirective = DL_ApplyOverrideToDirective(oNPC, nDirective, nOverrideKind);

    if (!DL_SupportsDirective(oNPC, nDirective))
    {
        return DL_GetSupportedFallbackDirective(oNPC);
    }

    return nDirective;
}

int DL_ResolveAnchorGroup(object oNPC, int nDirective)
{
    if (nDirective == DL_DIR_SLEEP)
    {
        return DL_AG_SLEEP;
    }
    if (nDirective == DL_DIR_WORK)
    {
        return DL_AG_WORK;
    }
    if (nDirective == DL_DIR_SERVICE)
    {
        return DL_AG_SERVICE;
    }
    if (nDirective == DL_DIR_SOCIAL)
    {
        return DL_AG_SOCIAL;
    }
    if (nDirective == DL_DIR_DUTY)
    {
        if (DL_GetNpcSubtype(oNPC) == DL_SUBTYPE_PATROL)
        {
            return DL_AG_PATROL_POINT;
        }
        return DL_AG_DUTY;
    }
    if (nDirective == DL_DIR_HOLD_POST)
    {
        return DL_AG_GATE;
    }
    if (nDirective == DL_DIR_LOCKDOWN_BASE || nDirective == DL_DIR_HIDE_SAFE)
    {
        return DL_AG_HIDE;
    }
    if (nDirective == DL_DIR_PUBLIC_PRESENCE)
    {
        return DL_AG_STREET_NEAR_BASE;
    }
    return DL_AG_NONE;
}

int DL_ResolveDialogueMode(object oNPC, int nDirective, int nOverrideKind)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = DL_GetNpcSubtype(oNPC);

    if (nOverrideKind == DL_OVR_FIRE)
    {
        if (nFamily == DL_FAMILY_LAW
            && DL_IsDutyDirective(nDirective))
        {
            return DL_DLG_INSPECTION;
        }
        return DL_DLG_HIDE;
    }
    if (DL_IsWorkOrServiceDirective(nDirective))
    {
        return DL_DLG_WORK;
    }
    if (DL_IsDutyDirective(nDirective))
    {
        if (nFamily == DL_FAMILY_LAW
            || nSubtype == DL_SUBTYPE_INSPECTION
            || nSubtype == DL_SUBTYPE_GATE_POST)
        {
            return DL_DLG_INSPECTION;
        }
        return DL_DLG_OFF_DUTY;
    }
    if (nDirective == DL_DIR_LOCKDOWN_BASE)
    {
        return DL_DLG_LOCKDOWN;
    }
    if (nDirective == DL_DIR_HIDE_SAFE)
    {
        return DL_DLG_HIDE;
    }
    if (DL_IsUnavailableDirective(nDirective))
    {
        return DL_DLG_UNAVAILABLE;
    }
    return DL_DLG_OFF_DUTY;
}

int DL_ResolveServiceMode(object oNPC, int nDirective, int nOverrideKind)
{
    int nFamily = DL_GetNpcFamily(oNPC);

    if (DL_ShouldDisableService(oNPC, nOverrideKind))
    {
        return DL_SERVICE_DISABLED;
    }
    if (DL_IsUnavailableDirective(nDirective))
    {
        return DL_SERVICE_NONE;
    }
    if (nFamily == DL_FAMILY_TRADE_SERVICE && nDirective == DL_DIR_SERVICE)
    {
        return DL_SERVICE_AVAILABLE;
    }
    if (nFamily == DL_FAMILY_CRAFT && nDirective == DL_DIR_WORK)
    {
        return DL_SERVICE_LIMITED;
    }
    return DL_SERVICE_DISABLED;
}

#endif
