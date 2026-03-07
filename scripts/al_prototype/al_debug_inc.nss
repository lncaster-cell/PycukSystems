// Debug helpers for sending messages to players in a specific area.

int AL_GetDebugLevel(object oContext)
{
    if (!GetIsObjectValid(oContext))
    {
        return 0;
    }

    int nLevel = GetLocalInt(oContext, "al_debug");
    if (nLevel > 0)
    {
        return nLevel;
    }

    object oArea = GetArea(oContext);
    if (GetIsObjectValid(oArea))
    {
        nLevel = GetLocalInt(oArea, "al_debug");
        if (nLevel > 0)
        {
            return nLevel;
        }
    }

    return 0;
}

int AL_DebugEnabledFor(object oContext, int nLevel)
{
    if (nLevel <= 0)
    {
        nLevel = 1;
    }

    return AL_GetDebugLevel(oContext) >= nLevel;
}

int AL_DebugEnabled(int nLevel)
{
    return AL_DebugEnabledFor(OBJECT_SELF, nLevel);
}

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
