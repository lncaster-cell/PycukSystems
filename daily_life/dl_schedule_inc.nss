#ifndef DL_SCHEDULE_INC_NSS
#define DL_SCHEDULE_INC_NSS

#include "dl_const_inc"
#include "dl_types_inc"

// Legacy compatibility include.
// New runtime entry scripts should prefer the compile-safe aggregation path via dl_all_inc.

int DL_GetDaysInMonth(int nYear, int nMonth)
{
    // Project calendar uses fixed 28-day months.
    return 28;
}

int DL_GetAbsoluteDayNumber()
{
    int nYear = GetCalendarYear();
    int nMonth = GetCalendarMonth();
    int nDay = GetCalendarDay();

    if (nYear < 0)
    {
        nYear = 0;
    }
    if (nMonth < 1)
    {
        nMonth = 1;
    }
    if (nMonth > 12)
    {
        nMonth = 12;
    }
    if (nDay < 0)
    {
        nDay = 0;
    }
    if (nDay > 28)
    {
        nDay = 28;
    }

    // Constant-time conversion for fixed 28-day months.
    return (nYear * 336) + ((nMonth - 1) * 28) + nDay;
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
    int nMinute = (nMinuteOfDay + nOffset) % 1440;
    if (nMinute < 0)
    {
        nMinute += 1440;
    }

    if (nTemplate == DL_SCH_EARLY_WORKER)
    {
        if (nMinute < 360)
        {
            return DL_WIN_SLEEP;
        }
        if (nMinute < 480)
        {
            return DL_WIN_MORNING_PREP;
        }
        if (nMinute < 1020)
        {
            return DL_WIN_WORK_CORE;
        }
        if (nMinute < 1260)
        {
            return DL_WIN_SOCIAL;
        }
        return DL_WIN_SLEEP;
    }

    if (nTemplate == DL_SCH_SHOP_DAY)
    {
        if (nMinute < 420)
        {
            return DL_WIN_SLEEP;
        }
        if (nMinute < 540)
        {
            return DL_WIN_MORNING_PREP;
        }
        if (nMinute < 1140)
        {
            return DL_WIN_SERVICE_CORE;
        }
        if (nMinute < 1260)
        {
            return DL_WIN_PUBLIC_IDLE;
        }
        return DL_WIN_SLEEP;
    }

    if (nTemplate == DL_SCH_TAVERN_LATE)
    {
        if (nMinute < 600)
        {
            return DL_WIN_SLEEP;
        }
        if (nMinute < 900)
        {
            return DL_WIN_PUBLIC_IDLE;
        }
        if (nMinute < 1380)
        {
            return DL_WIN_LATE_SOCIAL;
        }
        return DL_WIN_SLEEP;
    }

    if (nTemplate == DL_SCH_DUTY_ROTATION_DAY)
    {
        if (nMinute < 360)
        {
            return DL_WIN_SLEEP;
        }
        if (nMinute < 1080)
        {
            return DL_WIN_DAY_DUTY;
        }
        if (nMinute < 1260)
        {
            return DL_WIN_PUBLIC_IDLE;
        }
        return DL_WIN_SLEEP;
    }

    if (nTemplate == DL_SCH_DUTY_ROTATION_NIGHT)
    {
        if (nMinute < 420)
        {
            return DL_WIN_NIGHT_DUTY;
        }
        if (nMinute < 960)
        {
            return DL_WIN_SLEEP;
        }
        if (nMinute < 1200)
        {
            return DL_WIN_PUBLIC_IDLE;
        }
        return DL_WIN_NIGHT_DUTY;
    }

    if (nTemplate == DL_SCH_WANDERING_VENDOR_WINDOW)
    {
        if (nMinute < 420)
        {
            return DL_WIN_SLEEP;
        }
        if (nMinute < 1020)
        {
            return DL_WIN_SERVICE_CORE;
        }
        if (nMinute < 1200)
        {
            return DL_WIN_PUBLIC_IDLE;
        }
        return DL_WIN_SLEEP;
    }

    if (nDayType == DL_DAY_REST)
    {
        if (nMinute < 480)
        {
            return DL_WIN_SLEEP;
        }
        if (nMinute < 1140)
        {
            return DL_WIN_PUBLIC_IDLE;
        }
        if (nMinute < 1260)
        {
            return DL_WIN_SOCIAL;
        }
        return DL_WIN_SLEEP;
    }

    if (nMinute < 360)
    {
        return DL_WIN_SLEEP;
    }
    if (nMinute < 1020)
    {
        return DL_WIN_PUBLIC_IDLE;
    }
    if (nMinute < 1200)
    {
        return DL_WIN_SOCIAL;
    }
    return DL_WIN_SLEEP;
}

#endif
