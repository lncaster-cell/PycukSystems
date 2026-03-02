// Debug helpers for sending messages to players in a specific area.

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
