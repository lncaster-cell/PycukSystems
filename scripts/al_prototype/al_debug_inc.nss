// Debug helpers for sending messages to players in a specific area.

void AL_SendDebugMessageToAreaPCs(object oArea, string sMessage)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    object oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        if (GetIsPC(oObj))
        {
            SendMessageToPC(oObj, sMessage);
        }

        oObj = GetNextObjectInArea(oArea);
    }
}
