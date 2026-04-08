#include "dl_all_inc"

void main()
{
    object oArea = OBJECT_SELF;
    object oExiting = GetExitingObject();
    if (!GetIsPC(oExiting) || GetIsDM(oExiting))
    {
        return;
    }
    if (DL_HasAnyPlayersExcept(oArea, oExiting))
    {
        DL_OnAreaBecameWarm(oArea);
        return;
    }
    DL_OnAreaBecameFrozen(oArea);
}
