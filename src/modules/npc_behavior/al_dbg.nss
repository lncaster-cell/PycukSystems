// Temporary debug chat logger for quick NWScript event verification.

const int AL_DEBUG = TRUE;

void AL_Dbg(string sMsg)
{
    object oPc;

    if (!AL_DEBUG)
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
