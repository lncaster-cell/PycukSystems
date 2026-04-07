#include "dl_all_inc"

void main()
{
    object oArea = OBJECT_SELF;
    object oEntering = GetEnteringObject();
    if (!GetIsPC(oEntering) || GetIsDM(oEntering))
    {
        return;
    }
    DL_OnAreaBecameHot(oArea);
    DL_RequestAreaResync(oArea, DL_RESYNC_AREA_ENTER);
}
