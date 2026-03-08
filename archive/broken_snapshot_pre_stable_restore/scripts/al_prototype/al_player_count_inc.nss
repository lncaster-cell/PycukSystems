// Player counting helper for Ambient Life presence tracking.

#include "al_constants_inc"

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

// Handles a counted player leaving an area.
// Returns TRUE when the area became empty after decrement.
int AL_OnPlayerExitCount(object oPlayer, object oArea)
{
    if (!GetIsObjectValid(oPlayer) || !GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    if (GetLocalInt(oPlayer, AL_L_EXIT_COUNTED) == 1)
    {
        return FALSE;
    }

    SetLocalInt(oPlayer, AL_L_EXIT_COUNTED, 1);

    int iPlayers = GetLocalInt(oArea, AL_L_PLAYER_COUNT) - 1;
    if (iPlayers < 0)
    {
        iPlayers = 0;
    }

    SetLocalInt(oArea, AL_L_PLAYER_COUNT, iPlayers);
    return (iPlayers == 0);
}
