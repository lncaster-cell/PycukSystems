#include "al_area_constants_inc"
#include "al_debug_inc"

// Area mode contract helpers.
// This include intentionally provides only area-local read/check API wrappers,
// without introducing scheduler/runtime policy changes.

int AL_GetAreaModeOrLegacy(object oArea);
int AL_IsAreaInteriorByContract(object oArea);

string AL_TrimContractToken(string sValue)
{
    while (GetStringLength(sValue) > 0 && GetSubString(sValue, 0, 1) == " ")
    {
        sValue = GetSubString(sValue, 1, GetStringLength(sValue) - 1);
    }

    while (GetStringLength(sValue) > 0 && GetSubString(sValue, GetStringLength(sValue) - 1, 1) == " ")
    {
        sValue = GetSubString(sValue, 0, GetStringLength(sValue) - 1);
    }

    return sValue;
}

int AL_GetAreaModeLegacyDefault(object oArea)
{
    if (AL_IsAreaInteriorByContract(oArea))
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
                if (!GetIsObjectValid(oAdjacent))
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

int AL_GetAreaAdjacencyCount(object oArea)
{
    string sRaw = AL_GetAreaAdjacencyList(oArea);
    if (sRaw == "")
    {
        AL_LogAreaAdjFallbackDebug(oArea, "empty '" + AL_AREA_ADJ_LIST_LOCAL_KEY + "'; no neighbors");
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

        sToken = AL_TrimContractToken(sToken);
        if (sToken != "")
        {
            nCount++;
        }
    }

    if (nCount <= 0)
    {
        AL_LogAreaAdjFallbackDebug(oArea, "'" + AL_AREA_ADJ_LIST_LOCAL_KEY + "' has no valid area tags");
        return 0;
    }

    return nCount;
}

string AL_GetAreaAdjacentTagByIndex(object oArea, int nIndex)
{
    if (nIndex < 0)
    {
        return "";
    }

    string sRaw = AL_GetAreaAdjacencyList(oArea);
    if (sRaw == "")
    {
        return "";
    }

    int nCurrent = 0;
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

        sToken = AL_TrimContractToken(sToken);
        if (sToken == "")
        {
            continue;
        }

        if (nCurrent == nIndex)
        {
            return sToken;
        }

        nCurrent++;
    }

    return "";
}
