#include "al_constants_inc"
#include "al_area_constants_inc"
#include "al_debug_inc"

// Area mode contract helpers.
// This include intentionally provides only area-local read/check API wrappers,
// without introducing scheduler/runtime policy changes.

int AL_GetAreaModeOrLegacy(object oArea);
int AL_IsAreaInteriorByContract(object oArea);
void AL_SetAreaMode(object oArea, int iMode);
int AL_HasExplicitAreaMode(object oArea);

const string AL_AREA_MODE_IS_SET_LOCAL_KEY = "al_area_mode_is_set";

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

    if (GetLocalInt(oArea, AL_L_PLAYER_COUNT) > 0)
    {
        return AL_AREA_MODE_HOT;
    }

    return AL_AREA_MODE_COLD;
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
            sToken = AL_TrimContractToken(sToken);

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

    return GetLocalInt(oArea, AL_L_IS_INTERIOR) == 1;
}

void AL_LogAreaAdjFallbackDebug(object oArea, string sMessage)
{
    if (!GetIsObjectValid(oArea) || GetLocalInt(oArea, AL_L_DEBUG) != 1)
    {
        return;
    }

    AL_SendDebugMessageToAreaPCs(oArea, "AL: adjacency fallback -> " + sMessage);
}

void AL_SetAreaMode(object oArea, int iMode)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oArea, AL_AREA_MODE_LOCAL_KEY, iMode);
    SetLocalInt(oArea, AL_AREA_MODE_IS_SET_LOCAL_KEY, TRUE);
}

int AL_HasExplicitAreaMode(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    return GetLocalInt(oArea, AL_AREA_MODE_IS_SET_LOCAL_KEY) == TRUE;
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

    AL_SetAreaMode(oArea, AL_AREA_MODE_WARM);
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
            sAreaTag = AL_TrimContractToken(sAreaTag);

            if (sAreaTag != "")
            {
                object oAdjacent = OBJECT_INVALID;
                int iTagIndex = 0;

                while (TRUE)
                {
                    object oTagCandidate = GetObjectByTag(sAreaTag, iTagIndex);
                    if (!GetIsObjectValid(oTagCandidate))
                    {
                        break;
                    }

                    if (GetObjectType(oTagCandidate) == OBJECT_TYPE_AREA)
                    {
                        oAdjacent = oTagCandidate;
                        break;
                    }

                    AL_LogAreaAdjFallbackDebug(oSourceArea, "adjacent tag '" + sAreaTag + "' resolved to non-area object; skipped candidate");
                    iTagIndex++;
                }

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

// Contract note: explicit COLD (0) must be preserved. Legacy default applies
// only when al_area_mode is not explicitly set, or when explicit value is outside 0..3.
int AL_GetAreaModeOrLegacy(object oArea)
{
    if (!AL_HasExplicitAreaMode(oArea))
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
