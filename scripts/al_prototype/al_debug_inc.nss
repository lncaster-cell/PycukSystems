// Debug helpers for sending messages to players in a specific area.

const int AL_DEBUG_LEVEL_NONE = 0;
const int AL_DEBUG_LEVEL_L1 = 1;
const int AL_DEBUG_LEVEL_L2 = 2;

void AL_SendDebugMessageToAreaPCs(object oArea, string sMessage)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    // Standard debug traversal: GetFirstPC(FALSE)/GetNextPC(FALSE).
    // FALSE keeps recipients consistent across modules (players and DMs),
    // while the area filter below limits delivery to local observers only.
    object oObj = GetFirstPC(FALSE);
    while (GetIsObjectValid(oObj))
    {
        if (GetArea(oObj) == oArea)
        {
            SendMessageToPC(oObj, sMessage);
        }

        oObj = GetNextPC(FALSE);
    }
}

int AL_GetAreaDebugLevel(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return AL_DEBUG_LEVEL_NONE;
    }

    return GetLocalInt(oArea, "al_debug");
}

int AL_GetNpcDebugLevel(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return AL_DEBUG_LEVEL_NONE;
    }

    return GetLocalInt(oNpc, "al_debug");
}

int AL_GetDebugLevel(object oArea, object oNpc)
{
    int nAreaLevel = AL_GetAreaDebugLevel(oArea);
    int nNpcLevel = AL_GetNpcDebugLevel(oNpc);
    if (nNpcLevel > nAreaLevel)
    {
        return nNpcLevel;
    }

    return nAreaLevel;
}

int AL_IsDebugLevelEnabled(object oArea, object oNpc, int nMinLevel)
{
    return AL_GetDebugLevel(oArea, oNpc) >= nMinLevel;
}

void AL_DebugLog(object oArea, object oNpc, int nMinLevel, string sMessage)
{
    if (!AL_IsDebugLevelEnabled(oArea, oNpc, nMinLevel))
    {
        return;
    }

    AL_SendDebugMessageToAreaPCs(oArea, sMessage);
}

void AL_DebugLogL1(object oArea, object oNpc, string sMessage)
{
    AL_DebugLog(oArea, oNpc, AL_DEBUG_LEVEL_L1, sMessage);
}

void AL_DebugLogL2(object oArea, object oNpc, string sMessage)
{
    AL_DebugLog(oArea, oNpc, AL_DEBUG_LEVEL_L2, sMessage);
}
