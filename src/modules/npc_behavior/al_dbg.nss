// Temporary debug chat logger for quick NWScript event verification.
//
// Safe default is disabled (AL_DEBUG = FALSE).
// For local diagnostics without recompilation set runtime flag before event:
//   SetLocalInt(GetModule(), "AL_DEBUG", TRUE);
// Optional per-area override in area scripts/tools:
//   SetLocalInt(oArea, "AL_DEBUG", TRUE);
// Disable again when done:
//   DeleteLocalInt(GetModule(), "AL_DEBUG");
//   DeleteLocalInt(oArea, "AL_DEBUG");

const int AL_DEBUG = FALSE;

int AL_IsDebugEnabled()
{
    if (AL_DEBUG)
    {
        return TRUE;
    }

    if (GetLocalInt(GetModule(), "AL_DEBUG"))
    {
        return TRUE;
    }

    if (GetIsObjectValid(OBJECT_SELF) && GetLocalInt(OBJECT_SELF, "AL_DEBUG"))
    {
        return TRUE;
    }

    return FALSE;
}

void AL_Dbg(string sMsg)
{
    object oPc;

    if (!AL_IsDebugEnabled())
    {
        return;
    }

    oPc = GetFirstPC();
    if (!GetIsObjectValid(oPc))
    {
        return;
    }

    SendMessageToPC(oPc, "[DBG] " + sMsg);
}
