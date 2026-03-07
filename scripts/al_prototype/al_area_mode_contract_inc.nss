#include "al_area_constants_inc"
#include "al_debug_inc"

// Area mode contract helpers.
// This include intentionally provides only area-local read/check API wrappers,
// without introducing scheduler/runtime policy changes.

const string AL_AREA_MODE_PIN_LOCAL_KEY = "al_mode_pin";
const string AL_INTERIOR_MODE_WHITELIST_LOCAL_KEY = "al_interior_mode_whitelist";

const string AL_AREA_QUARTER_ID_LOCAL_KEY = "al_quarter_id";
const string AL_AREA_ADJ_COUNT_LOCAL_KEY = "al_adj_count";
const string AL_AREA_ADJ_KEY_PREFIX = "al_adj_";
const string AL_AREA_ADJ_CSV_LOCAL_KEY = "al_adjacent_areas";

const string AL_AREA_ADJ_CACHE_COUNT_KEY = "al_adj_csv_cache_count";
const string AL_AREA_ADJ_CACHE_KEY_PREFIX = "al_adj_csv_cache_";
const string AL_AREA_ADJ_CACHE_RAW_KEY = "al_adj_csv_cache_raw";

string AL_TrimSpaces(string sValue)
{
    int nLen = GetStringLength(sValue);

    int nStart = 0;
    while (nStart < nLen && GetSubString(sValue, nStart, 1) == " ")
    {
        nStart++;
    }

    int nEnd = nLen - 1;
    while (nEnd >= nStart && GetSubString(sValue, nEnd, 1) == " ")
    {
        nEnd--;
    }

    if (nEnd < nStart)
    {
        return "";
    }

    return GetSubString(sValue, nStart, nEnd - nStart + 1);
}

int AL_IsAreaDebugEnabled(object oArea)
{
    return GetLocalInt(oArea, "al_debug") == 1;
}

void AL_LogAdjacencyFallback(object oArea, string sMessage)
{
    if (!GetIsObjectValid(oArea) || !AL_IsAreaDebugEnabled(oArea))
    {
        return;
    }

    AL_SendDebugMessageToAreaPCs(oArea, "AL: adjacency fallback - " + sMessage);
}

int AL_IsAreaInteriorDefaultCold(object oArea)
{
    // Explicit mode pin has the highest precedence.
    if (GetLocalInt(oArea, AL_AREA_MODE_PIN_LOCAL_KEY) != 0)
    {
        return FALSE;
    }

    // Explicit content whitelist allows interior area to keep non-COLD mode.
    if (GetLocalInt(oArea, AL_INTERIOR_MODE_WHITELIST_LOCAL_KEY) == 1)
    {
        return FALSE;
    }

    return GetIsAreaInterior(oArea);
}

int AL_GetAreaModeLegacyDefault(object oArea)
{
    if (AL_IsAreaInteriorDefaultCold(oArea))
    {
        return AL_AREA_MODE_COLD;
    }

    if (GetLocalInt(oArea, "al_player_count") > 0)
    {
        return AL_AREA_MODE_HOT;
    }

    return AL_AREA_MODE_COLD;
}

int AL_GetAreaModeOrLegacy(object oArea)
{
    int iMode = GetLocalInt(oArea, AL_AREA_MODE_LOCAL_KEY);
    if (iMode == AL_AREA_MODE_HOT
        || iMode == AL_AREA_MODE_WARM
        || iMode == AL_AREA_MODE_COLD
        || iMode == AL_AREA_MODE_OFF)
    {
        return iMode;
    }

    return AL_GetAreaModeLegacyDefault(oArea);
}

int AL_IsAreaModeHot(object oArea)
{
    return AL_GetAreaModeOrLegacy(oArea) == AL_AREA_MODE_HOT;
}

int AL_IsAreaModeWarm(object oArea)
{
    return AL_GetAreaModeOrLegacy(oArea) == AL_AREA_MODE_WARM;
}

int AL_IsAreaModeCold(object oArea)
{
    return AL_GetAreaModeOrLegacy(oArea) == AL_AREA_MODE_COLD;
}

int AL_IsAreaModeOff(object oArea)
{
    return AL_GetAreaModeOrLegacy(oArea) == AL_AREA_MODE_OFF;
}

string AL_GetAdjacencyLocalKey(int nIndex)
{
    return AL_AREA_ADJ_KEY_PREFIX + IntToString(nIndex);
}

void AL_ResetAdjacencyCsvCache(object oArea, int nOldCount)
{
    int i = 0;
    while (i < nOldCount)
    {
        DeleteLocalString(oArea, AL_AREA_ADJ_CACHE_KEY_PREFIX + IntToString(i));
        i++;
    }

    DeleteLocalInt(oArea, AL_AREA_ADJ_CACHE_COUNT_KEY);
    DeleteLocalString(oArea, AL_AREA_ADJ_CACHE_RAW_KEY);
}

int AL_HasValidAdjacencyDenseLocals(object oArea)
{
    int nCount = GetLocalInt(oArea, AL_AREA_ADJ_COUNT_LOCAL_KEY);
    if (nCount <= 0)
    {
        return FALSE;
    }

    int i = 0;
    while (i < nCount)
    {
        string sTag = AL_TrimSpaces(GetLocalString(oArea, AL_GetAdjacencyLocalKey(i)));
        if (sTag == "")
        {
            AL_LogAdjacencyFallback(oArea, "empty local " + AL_GetAdjacencyLocalKey(i) + ".");
            return FALSE;
        }

        i++;
    }

    return TRUE;
}

int AL_BuildAdjacencyCsvCache(object oArea)
{
    string sRaw = GetLocalString(oArea, AL_AREA_ADJ_CSV_LOCAL_KEY);
    string sPrevRaw = GetLocalString(oArea, AL_AREA_ADJ_CACHE_RAW_KEY);
    int nPrevCount = GetLocalInt(oArea, AL_AREA_ADJ_CACHE_COUNT_KEY);

    if (sRaw == sPrevRaw && nPrevCount > 0)
    {
        return nPrevCount;
    }

    AL_ResetAdjacencyCsvCache(oArea, nPrevCount);

    if (sRaw == "")
    {
        AL_LogAdjacencyFallback(oArea, "CSV local al_adjacent_areas is empty.");
        return 0;
    }

    int nCount = 0;
    while (sRaw != "")
    {
        int nComma = FindSubString(sRaw, ",");
        string sToken = sRaw;

        if (nComma >= 0)
        {
            sToken = GetSubString(sRaw, 0, nComma);
            sRaw = GetSubString(sRaw, nComma + 1, GetStringLength(sRaw) - (nComma + 1));
        }
        else
        {
            sRaw = "";
        }

        sToken = AL_TrimSpaces(sToken);
        if (sToken == "")
        {
            continue;
        }

        SetLocalString(oArea, AL_AREA_ADJ_CACHE_KEY_PREFIX + IntToString(nCount), sToken);
        nCount++;
    }

    if (nCount <= 0)
    {
        AL_LogAdjacencyFallback(oArea, "CSV local al_adjacent_areas has no valid area tags.");
        return 0;
    }

    SetLocalString(oArea, AL_AREA_ADJ_CACHE_RAW_KEY, GetLocalString(oArea, AL_AREA_ADJ_CSV_LOCAL_KEY));
    SetLocalInt(oArea, AL_AREA_ADJ_CACHE_COUNT_KEY, nCount);
    return nCount;
}

int AL_GetAreaAdjacencyCount(object oArea)
{
    if (AL_HasValidAdjacencyDenseLocals(oArea))
    {
        return GetLocalInt(oArea, AL_AREA_ADJ_COUNT_LOCAL_KEY);
    }

    return AL_BuildAdjacencyCsvCache(oArea);
}

string AL_GetAreaAdjacentTagByIndex(object oArea, int nIndex)
{
    if (nIndex < 0)
    {
        return "";
    }

    if (AL_HasValidAdjacencyDenseLocals(oArea))
    {
        if (nIndex >= GetLocalInt(oArea, AL_AREA_ADJ_COUNT_LOCAL_KEY))
        {
            return "";
        }

        return AL_TrimSpaces(GetLocalString(oArea, AL_GetAdjacencyLocalKey(nIndex)));
    }

    int nCount = AL_BuildAdjacencyCsvCache(oArea);
    if (nIndex >= nCount)
    {
        return "";
    }

    return GetLocalString(oArea, AL_AREA_ADJ_CACHE_KEY_PREFIX + IntToString(nIndex));
}
