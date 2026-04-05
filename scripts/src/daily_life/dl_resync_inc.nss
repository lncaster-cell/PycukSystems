#include "dl_const_inc"
#include "dl_types_inc"
#include "dl_materialize_inc"
#include "dl_interact_inc"

int DL_ShouldResync(object oNPC, int nReason)
{
    if (!DL_IsDailyLifeNpc(oNPC))
    {
        return FALSE;
    }
    if (!DL_IsPersistent(oNPC) && !DL_IsNamed(oNPC))
    {
        return GetLocalInt(oNPC, DL_L_RESYNC_PENDING) == TRUE;
    }
    return nReason != DL_RESYNC_NONE;
}

int DL_NormalizeResyncReason(int nReason)
{
    if (nReason == DL_RESYNC_NONE)
    {
        return DL_RESYNC_WORKER;
    }
    return nReason;
}

int DL_GetResyncReasonPriority(int nReason)
{
    if (nReason == DL_RESYNC_BASE_LOST)
    {
        return 5;
    }
    if (nReason == DL_RESYNC_SLOT_ASSIGNED)
    {
        return 4;
    }
    if (nReason == DL_RESYNC_OVERRIDE_END || nReason == DL_RESYNC_TIME_JUMP)
    {
        return 3;
    }
    if (nReason == DL_RESYNC_SAVE_LOAD || nReason == DL_RESYNC_TIER_UP)
    {
        return 2;
    }
    if (nReason == DL_RESYNC_AREA_ENTER)
    {
        return 1;
    }
    if (nReason == DL_RESYNC_WORKER)
    {
        return 0;
    }
    return -1;
}

int DL_SelectStrongerResyncReason(int nCurrentReason, int nRequestedReason)
{
    if (DL_GetResyncReasonPriority(nRequestedReason) >= DL_GetResyncReasonPriority(nCurrentReason))
    {
        return nRequestedReason;
    }
    return nCurrentReason;
}

void DL_RequestResync(object oNPC, int nReason)
{
    int nCurrentReason;

    if (!DL_IsDailyLifeNpc(oNPC))
    {
        return;
    }

    nReason = DL_NormalizeResyncReason(nReason);
    nCurrentReason = DL_NormalizeResyncReason(GetLocalInt(oNPC, DL_L_RESYNC_REASON));

    SetLocalInt(oNPC, DL_L_RESYNC_PENDING, TRUE);
    SetLocalInt(oNPC, DL_L_RESYNC_REASON, DL_SelectStrongerResyncReason(nCurrentReason, nReason));
}

void DL_RequestAreaResync(object oArea, int nReason)
{
    object oObject = GetFirstObjectInArea(oArea);

    while (GetIsObjectValid(oObject))
    {
        if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject))
        {
            DL_RequestResync(oObject, nReason);
        }
        oObject = GetNextObjectInArea(oArea);
    }
}

void DL_RequestModuleResync(int nReason)
{
    object oArea = GetFirstArea();

    while (GetIsObjectValid(oArea))
    {
        DL_RequestAreaResync(oArea, nReason);
        oArea = GetNextArea();
    }
}

void DL_RunResync(object oNPC, object oArea, int nReason)
{
    nReason = DL_NormalizeResyncReason(nReason);

    if (!DL_ShouldResync(oNPC, nReason))
    {
        return;
    }

    DL_MaterializeNpc(oNPC, oArea);
    DeleteLocalInt(oNPC, DL_L_RESYNC_PENDING);
    SetLocalInt(oNPC, DL_L_RESYNC_REASON, DL_RESYNC_NONE);
}

void DL_RunForcedResync(object oNPC, object oArea, int nReason)
{
    if (!DL_IsDailyLifeNpc(oNPC))
    {
        return;
    }

    DL_RequestResync(oNPC, nReason);
    DL_RunResync(oNPC, oArea, nReason);
}
