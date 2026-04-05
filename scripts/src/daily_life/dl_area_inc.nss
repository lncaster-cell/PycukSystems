#ifndef DL_AREA_INC_NSS
#define DL_AREA_INC_NSS

#include "dl_const_inc"
#include "dl_log_inc"
#include "dl_util_inc"

int DL_GetAreaTier(object oArea)
{
    return GetLocalInt(oArea, DL_L_AREA_TIER);
}

void DL_SetAreaTier(object oArea, int nTier)
{
    SetLocalInt(oArea, DL_L_AREA_TIER, nTier);
}

int DL_ShouldRunDailyLifeTier(int nTier)
{
    return nTier == DL_AREA_HOT || nTier == DL_AREA_WARM;
}

int DL_ShouldRunDailyLife(object oArea)
{
    return DL_ShouldRunDailyLifeTier(DL_GetAreaTier(oArea));
}

void DL_OnAreaBecameHot(object oArea)
{
    DL_SetAreaTier(oArea, DL_AREA_HOT);
    DL_Log(DL_DEBUG_BASIC, "Area HOT: " + GetTag(oArea));
}

void DL_OnAreaBecameWarm(object oArea)
{
    DL_SetAreaTier(oArea, DL_AREA_WARM);
    DL_Log(DL_DEBUG_BASIC, "Area WARM: " + GetTag(oArea));
}

void DL_OnAreaBecameFrozen(object oArea)
{
    DL_SetAreaTier(oArea, DL_AREA_FROZEN);
    DL_Log(DL_DEBUG_BASIC, "Area FROZEN: " + GetTag(oArea));
}

#endif
