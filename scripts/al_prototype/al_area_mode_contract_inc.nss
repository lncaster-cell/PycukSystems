#include "al_area_constants_inc"
#include "al_debug_inc"

// Area mode contract helpers.
// This include intentionally provides only area-local read/check API wrappers,
// without introducing scheduler/runtime policy changes.

int AL_GetAreaModeOrLegacy(object oArea);

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

string AL_GetAreaQuarterId(object oArea)
{
    return GetLocalString(oArea, AL_AREA_QUARTER_LOCAL_KEY);
}

string AL_GetAreaAdjacencyList(object oArea)
{
    return GetLocalString(oArea, AL_AREA_ADJ_LIST_LOCAL_KEY);
}

string AL_GetAreaAdjInteriorWhitelist(object oArea)
{
    return GetLocalString(oArea, AL_AREA_ADJ_INTERIOR_WHITELIST_LOCAL_KEY);
}

int AL_IsAreaInInteriorAdjWhitelist(object oSourceArea, string sAreaTag)
{
    if (!GetIsObjectValid(oSourceArea) || sAreaTag == "")
    {
        return FALSE;
    }

    string sList = AL_GetAreaAdjInteriorWhitelist(oSourceArea);
    if (sList == "")
    {
        return FALSE;
    }

    int iLen = GetStringLength(sList);
    int iStart = 0;
    int i = 0;

    while (i <= iLen)
    {
        if (i == iLen || GetSubString(sList, i, 1) == ",")
        {
            string sToken = GetSubString(sList, iStart, i - iStart);
            while (GetStringLength(sToken) > 0 && GetSubString(sToken, 0, 1) == " ")
            {
                sToken = GetSubString(sToken, 1, GetStringLength(sToken) - 1);
            }
            while (GetStringLength(sToken) > 0 && GetSubString(sToken, GetStringLength(sToken) - 1, 1) == " ")
            {
                sToken = GetSubString(sToken, 0, GetStringLength(sToken) - 1);
            }

            if (sToken == sAreaTag)
            {
                return TRUE;
            }

            iStart = i + 1;
        }
        i++;
    }

    return FALSE;
}

int AL_IsAreaInteriorByContract(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    return GetLocalInt(oArea, "al_is_interior") == 1;
}

void AL_LogAreaAdjFallbackDebug(object oArea, string sMessage)
{
    if (!GetIsObjectValid(oArea) || GetLocalInt(oArea, "al_debug") != 1)
    {
        return;
    }

    AL_SendDebugMessageToAreaPCs(oArea, "AL: adjacency fallback -> " + sMessage);
}

void AL_SetAreaModeClampedWarm(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    int iCurrent = AL_GetAreaModeOrLegacy(oArea);
    if (iCurrent >= AL_AREA_MODE_WARM)
    {
        return;
    }

    SetLocalInt(oArea, AL_AREA_MODE_LOCAL_KEY, AL_AREA_MODE_WARM);
}

void AL_SoftActivateAdjacentAreas(object oSourceArea)
{
    if (!GetIsObjectValid(oSourceArea))
    {
        return;
    }

    string sAdjacency = AL_GetAreaAdjacencyList(oSourceArea);
    if (sAdjacency == "")
    {
        AL_LogAreaAdjFallbackDebug(oSourceArea, "empty '" + AL_AREA_ADJ_LIST_LOCAL_KEY + "'; local-only heat update");
        return;
    }

    int iLen = GetStringLength(sAdjacency);
    int iStart = 0;
    int i = 0;
    int bApplied = FALSE;

    while (i <= iLen)
    {
        if (i == iLen || GetSubString(sAdjacency, i, 1) == ",")
        {
            string sAreaTag = GetSubString(sAdjacency, iStart, i - iStart);
            while (GetStringLength(sAreaTag) > 0 && GetSubString(sAreaTag, 0, 1) == " ")
            {
                sAreaTag = GetSubString(sAreaTag, 1, GetStringLength(sAreaTag) - 1);
            }
            while (GetStringLength(sAreaTag) > 0 && GetSubString(sAreaTag, GetStringLength(sAreaTag) - 1, 1) == " ")
            {
                sAreaTag = GetSubString(sAreaTag, 0, GetStringLength(sAreaTag) - 1);
            }

            if (sAreaTag != "")
            {
                object oAdjacent = GetObjectByTag(sAreaTag, 0);
                if (!GetIsObjectValid(oAdjacent) || GetObjectType(oAdjacent) != OBJECT_TYPE_AREA)
                {
                    AL_LogAreaAdjFallbackDebug(oSourceArea, "unknown adjacent area tag '" + sAreaTag + "'; skipped");
                }
                else
                {
                    // Interior neighbors are opt-in via whitelist only.
                    if (AL_IsAreaInteriorByContract(oAdjacent) && !AL_IsAreaInInteriorAdjWhitelist(oSourceArea, sAreaTag))
                    {
                        AL_LogAreaAdjFallbackDebug(oSourceArea, "interior neighbor '" + sAreaTag + "' is not in '" + AL_AREA_ADJ_INTERIOR_WHITELIST_LOCAL_KEY + "'; skipped");
                    }
                    else
                    {
                        // Soft activation contract: never push neighbors above WARM
                        // and do not schedule/chain any additional framework work.
                        AL_SetAreaModeClampedWarm(oAdjacent);
                        bApplied = TRUE;
                    }
                }
            }

            iStart = i + 1;
        }
        i++;
    }

    if (!bApplied)
    {
        AL_LogAreaAdjFallbackDebug(oSourceArea, "no valid neighbors to warm; local-only heat update");
    }
}

int AL_GetAreaModeOrLegacy(object oArea)
{
    // Legacy behavior remains default until per-area mode flags are enabled.
    if (!AL_IsAreaModeFlagsEnabled(oArea))
    {
        return AL_GetAreaModeLegacyDefault(oArea);
    }

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
