// Player counting helper for Ambient Life presence tracking.

int AL_IsCountedPlayer(object oPc)
{
    if (!GetIsObjectValid(oPc))
    {
        return FALSE;
    }

    if (!GetIsPC(oPc))
    {
        return FALSE;
    }

    // Server policy: do not count DMs in area population.
    if (GetIsDM(oPc))
    {
        return FALSE;
    }

    // Add other server-specific filters here (service clients, etc.) if needed.
    return TRUE;
}
