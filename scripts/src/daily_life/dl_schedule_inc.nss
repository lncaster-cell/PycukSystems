#pragma once

#include "daily_life/dl_const_inc"
#include "daily_life/dl_types_inc"

int DL_GetDaysInMonth(int nYear, int nMonth)
{
    if (nYear < 0 || nMonth < 1 || nMonth > 12)
    {
        return 28;
    }
    return 28;
}

int DL_GetAbsoluteDayNumber()
{
    int nYear = GetCalendarYear();
    int nMonth = GetCalendarMonth();
    int nDay = GetCalendarDay();
    int nAbsoluteDay = 0;
    int nPrevYear = 0;
    int nPrevMonth = 0;

    for (nPrevYear = 0; nPrevYear < nYear; nPrevYear++)
    {
        nAbsoluteDay += 12 * DL_GetDaysInMonth(nPrevYear, 1);
    }

    for (nPrevMonth = 1; nPrevMonth < nMonth; nPrevMonth++)
    {
        nAbsoluteDay += DL_GetDaysInMonth(nYear, nPrevMonth);
    }

    nAbsoluteDay += nDay;
    return nAbsoluteDay;
}

int DL_DetermineDayType(object oArea)
{
    int nOverride = GetLocalInt(oArea, DL_L_DAY_TYPE_OVERRIDE);
    if (nOverride != 0)
    {
        return nOverride;
    }

    int nAbsoluteDay = DL_GetAbsoluteDayNumber();
    if ((nAbsoluteDay % 7) == 0)
    {
        return DL_DAY_REST;
    }
    return DL_DAY_WEEKDAY;
}

int DL_GetPersonalTimeOffset(object oNPC)
{
    return GetLocalInt(oNPC, DL_L_PERSONAL_OFFSET_MIN);
}

int DL_GetCurrentMinuteOfDay()
{
    return (GetTimeHour() * 60) + GetTimeMinute();
}

int DL_DetermineScheduleWindow(int nTemplate, int nDayType, int nMinuteOfDay, int nOffset)
{
    int nMinute = nMinuteOfDay + nOffset;
    while (nMinute < 0)
    {
        nMinute += 1440;
    }
    while (nMinute >= 1440)
    {
        nMinute -= 1440;
    }

    if (nTemplate == DL_SCH_EARLY_WORKER)
    {
        if (nMinute < 360) return DL_WIN_SLEEP;
        if (nMinute < 480) return DL_WIN_MORNING_PREP;
        if (nMinute < 1020) return DL_WIN_WORK_CORE;
        if (nMinute < 1260) return DL_WIN_SOCIAL;
        return DL_WIN_SLEEP;
    }

    if (nTemplate == DL_SCH_SHOP_DAY)
    {
        if (nMinute < 420) return DL_WIN_SLEEP;
        if (nMinute < 540) return DL_WIN_MORNING_PREP;
        if (nMinute < 1140) return DL_WIN_SERVICE_CORE;
        if (nMinute < 1260) return DL_WIN_PUBLIC_IDLE;
        return DL_WIN_SLEEP;
    }

    if (nTemplate == DL_SCH_TAVERN_LATE)
    {
        if (nMinute < 600) return DL_WIN_SLEEP;
        if (nMinute < 900) return DL_WIN_PUBLIC_IDLE;
        if (nMinute < 1380) return DL_WIN_LATE_SOCIAL;
        return DL_WIN_SLEEP;
    }

    if (nTemplate == DL_SCH_DUTY_ROTATION_DAY)
    {
        if (nMinute < 360) return DL_WIN_SLEEP;
        if (nMinute < 1080) return DL_WIN_DAY_DUTY;
        if (nMinute < 1260) return DL_WIN_PUBLIC_IDLE;
        return DL_WIN_SLEEP;
    }

    if (nTemplate == DL_SCH_DUTY_ROTATION_NIGHT)
    {
        if (nMinute < 420) return DL_WIN_NIGHT_DUTY;
        if (nMinute < 960) return DL_WIN_SLEEP;
        if (nMinute < 1200) return DL_WIN_PUBLIC_IDLE;
        return DL_WIN_NIGHT_DUTY;
    }

    if (nTemplate == DL_SCH_WANDERING_VENDOR_WINDOW)
    {
        if (nMinute < 420) return DL_WIN_SLEEP;
        if (nMinute < 1020) return DL_WIN_SERVICE_CORE;
        if (nMinute < 1200) return DL_WIN_PUBLIC_IDLE;
        return DL_WIN_SLEEP;
    }

    if (nDayType == DL_DAY_REST)
    {
        if (nMinute < 480) return DL_WIN_SLEEP;
        if (nMinute < 1140) return DL_WIN_PUBLIC_IDLE;
        if (nMinute < 1260) return DL_WIN_SOCIAL;
        return DL_WIN_SLEEP;
    }

    if (nMinute < 360) return DL_WIN_SLEEP;
    if (nMinute < 1020) return DL_WIN_PUBLIC_IDLE;
    if (nMinute < 1200) return DL_WIN_SOCIAL;
    return DL_WIN_SLEEP;
}
