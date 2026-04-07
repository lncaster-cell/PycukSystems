#include "dl_all_inc"

void main()
{
    object oArea = GetFirstArea();
    DL_Log(DL_DEBUG_BASIC, "Daily Life load hook initialized");
    while (GetIsObjectValid(oArea))
    {
        if (DL_HasAnyPlayers(oArea)) DL_OnAreaBecameHot(oArea);
        else DL_OnAreaBecameFrozen(oArea);
        if (DL_ShouldRunDailyLife(oArea)) DL_RequestAreaResync(oArea, DL_RESYNC_SAVE_LOAD);
        oArea = GetNextArea();
    }
}
