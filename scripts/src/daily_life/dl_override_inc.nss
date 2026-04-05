#ifndef DL_OVERRIDE_INC_NSS
#define DL_OVERRIDE_INC_NSS

#include "dl_const_inc"
#include "dl_types_inc"

int DL_GetTopOverride(object oNPC, object oArea)
{
    int nOverride = GetLocalInt(oNPC, DL_L_OVERRIDE_KIND);
    if (nOverride != DL_OVR_NONE)
    {
        return nOverride;
    }

    nOverride = GetLocalInt(oArea, DL_L_OVERRIDE_KIND);
    if (nOverride != DL_OVR_NONE)
    {
        return nOverride;
    }

    return GetLocalInt(GetModule(), DL_L_OVERRIDE_KIND);
}

int DL_HasCriticalOverride(object oNPC, object oArea)
{
    int nOverride = DL_GetTopOverride(oNPC, oArea);
    return nOverride == DL_OVR_FIRE || nOverride == DL_OVR_QUARANTINE;
}

int DL_ShouldSuppressMaterialization(object oNPC, int nOverrideKind)
{
    if (nOverrideKind == DL_OVR_FIRE)
    {
        return DL_GetNpcFamily(oNPC) != DL_FAMILY_LAW;
    }

    if (nOverrideKind == DL_OVR_QUARANTINE)
    {
        int nFamily = DL_GetNpcFamily(oNPC);
        return nFamily != DL_FAMILY_LAW;
    }

    return FALSE;
}

int DL_ShouldDisableService(object oNPC, int nOverrideKind)
{
    if (nOverrideKind == DL_OVR_FIRE)
    {
        return TRUE;
    }

    if (nOverrideKind == DL_OVR_QUARANTINE)
    {
        return DL_GetNpcFamily(oNPC) != DL_FAMILY_LAW;
    }

    return FALSE;
}

#endif
