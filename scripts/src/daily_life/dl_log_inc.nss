#pragma once

#include "daily_life/dl_const_inc"

void DL_Log(int nLevel, string sMessage)
{
    if (nLevel > DL_DEBUG_LEVEL)
    {
        return;
    }

    WriteTimestampedLogEntry("[DLV1] " + sMessage);
}

void DL_LogNpc(object oNPC, int nLevel, string sMessage)
{
    string sTag = "<invalid>";
    if (GetIsObjectValid(oNPC))
    {
        sTag = GetTag(oNPC);
    }
    DL_Log(nLevel, sTag + ": " + sMessage);
}
